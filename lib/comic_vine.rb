require "comic_vine/version"
require "net/http"

module ComicVine
  class Railtie < Rails::Railtie
    config.after_initialize do
      if File.exists? Rails.root.join('config', 'cv_key.yml')
        keyfile = YAML::load(File.open(Rails.root.join('config', 'cv_key.yml')))
        ComicVine::API.key = keyfile['cvkey']
      else
        ComicVine::API.key = 'no_keyfile_found'
      end
    end
  end
  
  class CVError < StandardError  
  end
  
  class CVList
    include Enumerable
    
    attr_reader :total_count
    attr_reader :offset
    attr_reader :limit
    attr_reader :cvos
    
    def initialize(resp)      
      @total_count = resp['number_of_total_results']
      @offset = resp['offset']
      @limit = resp['limit']
    end
    
    def each
      @cvos.each { |c| yield c }
    end
    
    def last
      @cvos.last
    end
    
    protected
      def update_ivals(new_cvol)
        @total_count = new_cvol.total_count
        @offset = new_cvol.offset
        @limit = new_cvol.limit

        @cvos = new_cvol.cvos
      end
  end
  
  class CVObjectList < CVList
    attr_reader :resource
    
    def initialize(resp, resc)      
      super(resp)
      
      @resource = resc
      @cvos = resp['results'].map{ |r| ComicVine::CVObject.new(r)}
    end
    
    def next_page
      return nil if (@offset + count) == @total_count
      update_ivals(ComicVine::API.send(@resource, {:limit => @limit, :offset => (@offset + count)}))
    end
    
    def prev_page
      return nil if @offset == 0
      update_ivals(ComicVine::API.send(@resource, {:limit => @limit, :offset => (@offset - count)}))
    end
  end
  
  class CVSearchList < CVList
    attr_reader :resource
    attr_reader :query
    
    def initialize(resp, resc, query)      
      super(resp)
      
      @resource = resc
      @query = query
      @cvos = resp['results'].map{ |r| ComicVine::CVSearchObject.new(r)}
    end
    
    def next_page
      return nil if (@offset + count) == @total_count
      update_ivals(ComicVine::API.search(@resource, @query, {:limit => @limit, :offset => (@offset + count)}))
    end
    
    def prev_page
      return nil if @offset == 0
      update_ivals(ComicVine::API.search(@resource, @query, {:limit => @limit, :offset => (@offset - count)}))
    end
  end
  
  class CVObject
    def initialize(args)
      args.each do |k,v|
        class_eval { attr_accessor k }
        instance_variable_set "@#{k}", v
      end
    end
    
    def method_missing(method_sym, *arguments, &block)
      if method_sym.to_s =~ /^get_(.*)$/
        key = method_sym.to_s.sub "get_", ""
        if instance_variable_defined?("@#{key}")
          if ComicVine::API::LIST_ACTIONS.include?(key.to_sym)
            res = []
            send(key).each do |i|
              res << ComicVine::API.send(key.singularize, i['id'])
            end
            return res
          end
          if ComicVine::API::LIST_ACTIONS.include?(key.pluralize.to_sym)
            return ComicVine::API.send(key, send(key)['id'])
          end
        else
          super
        end
      elsif
        super
      end
    end
  end
  
  class CVSearchObject < CVObject
    def fetch
      ComicVine::API.send(@resource_type, @id)
    end
  end
  
  class API
    cattr_accessor :key
    
    API_BASE_URL = "http://api.comicvine.com/"
    
    LIST_ACTIONS = [ :characters,
                      :chats,
                      :concepts,
                      :issues,
                      :locations,
                      :movies,
                      :objects,
                      :origins,
                      :persons,
                      :powers,
                      :promos,
                      :publishers,
                      :story_arcs,
                      :teams,
                      :videos,
                      :video_types,
                      :volumes ].freeze
    
    def self.search res, query, opts={}
      resp = hit_api(build_url("search", opts)+"&resources=#{res}&query=#{query}")
      ComicVine::CVSearchList.new(resp, res, query)
    end
    
    def self.method_missing(method_sym, *arguments, &block)
      if LIST_ACTIONS.include?(method_sym)
        self.get_list method_sym.to_s, arguments.first
      elsif LIST_ACTIONS.include?(method_sym.to_s.pluralize.to_sym)
        self.get_item method_sym, *arguments
      elsif
        super
      end
    end
    
    private
      def self.get_list list_type, opts={}
        resp = hit_api(build_url(list_type, opts))
        ComicVine::CVObjectList.new(resp, list_type)
      end
      
      def self.get_item item_type, id, opts={}
        resp = hit_api(build_url("#{item_type}/#{id}", opts))
        ComicVine::CVObject.new(resp['results'])
      end
      
      def self.hit_api url
        url = URI.parse(url)
        resp = Net::HTTP.get(url)
        presp = JSON.parse(resp)
        raise CVError, presp['error'] unless presp['status_code'] == 1
        presp
      end
      
      def self.build_url action, opts={}
        query = ''
        query = "&#{opts.to_query}" if !opts.nil?
        API_BASE_URL+action+"/?format=json&api_key=#{@@key}#{query}"
      end
  end
end
