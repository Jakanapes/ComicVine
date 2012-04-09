require "comic_vine/version"
require "net/http"

module ComicVine
  class CVObject
    def initialize(args)
      args.each do |k,v|
        class_eval { attr_accessor k }
        instance_variable_set "@#{k}", v
      end
    end
    
    def method_missing(method_sym, *arguments, &block)
      if method_sym.to_s =~ /^get_(.*)$/
        get, key = method_sym.to_s.split "_"
        if instance_variable_defined?("@#{key}") && ComicVine::API::LIST_ACTIONS.include?(key.to_sym)
          res = []
          send(key).each do |i|
            res << ComicVine::API.send(key.singularize, i['id'])
          end
          return res
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
    
    def self.search res, query
      hit_api(build_url("search")+"&resources=#{res}&query=#{query}")
    end
    
    def self.method_missing(method_sym, *arguments, &block)
      if LIST_ACTIONS.include?(method_sym)
        self.get_list method_sym.to_s
      elsif LIST_ACTIONS.include?(method_sym.to_s.pluralize.to_sym)
        self.get_item method_sym, arguments.first
      elsif
        super
      end
    end
    
    private
      def self.get_list list_type
        hit_api(build_url(list_type))
      end
      
      def self.get_item item_type, id
        hit_api(build_url("#{item_type}/#{id}"))
      end
      
      def self.hit_api url
        url = URI.parse(url)
        resp = Net::HTTP.get(url)
        presp = JSON.parse(resp)
        if presp['results'].kind_of?(Array)
          presp['results'].map{ |r| ComicVine::CVObject.new(r)}
        else
          ComicVine::CVObject.new(presp['results'])
        end
      end
      
      def self.build_url action
        API_BASE_URL+action+"/?api_key=#{@@key}&format=json"
      end
  end
end
