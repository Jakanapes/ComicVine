require "comic_vine/version"
require "net/http"

module ComicVine
  
  class CVError < StandardError  
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
      def self.get_list list_type, opts=nil
        resp = hit_api(build_url(list_type, opts))
        ComicVine::CVObjectList.new(resp, list_type)
      end
      
      def self.get_item item_type, id, opts=nil
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
      
      def self.build_url action, opts=nil
        query = ''
        query = "&#{opts.to_query}" if !opts.nil?
        API_BASE_URL+action+"/?format=json&api_key=#{@@key}#{query}"
      end
  end
end

require 'comic_vine/cv_object'
require 'comic_vine/cv_list'
