require "comic_vine/version"
require "net/http"

module ComicVine
  class Railtie < Rails::Railtie
    config.after_initialize do
      keyfile = YAML::load(File.open(Rails.root.join('config', 'cv_key.yml')))
      ComicVine::API.key = keyfile['cvkey']
    end
  end
  
  class CVError < StandardError  
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
      hit_api(build_url("search", opts)+"&resources=#{res}&query=#{query}")
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
        hit_api(build_url(list_type, opts))
      end
      
      def self.get_item item_type, id, opts={}
        hit_api(build_url("#{item_type}/#{id}", opts))
      end
      
      def self.hit_api url
        url = URI.parse(url)
        resp = Net::HTTP.get(url)
        presp = JSON.parse(resp)
        raise CVError, presp['error'] unless presp['status_code'] == 1
        if presp['results'].kind_of?(Array)
          presp['results'].map{ |r| ComicVine::CVObject.new(r)}
        else
          ComicVine::CVObject.new(presp['results'])
        end
      end
      
      def self.build_url action, opts={}
        query = ''
        query = "&#{opts.to_query}" if !opts.nil?
        API_BASE_URL+action+"/?format=json&api_key=#{@@key}#{query}"
      end
  end
end
