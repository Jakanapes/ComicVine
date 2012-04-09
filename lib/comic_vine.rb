require "comic_vine/version"
require "net/http"

module ComicVine
  class API
    cattr_accessor :key
    
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
      url = URI.parse("http://api.comicvine.com/search/?api_key=#{@@key}&format=json&resources=#{res}&query=#{query}")
      resp = Net::HTTP.get(url)
      JSON.parse(resp)['results']
    end
    
    def self.method_missing(method_sym, *arguments, &block)
      if LIST_ACTIONS.include?(method_sym)
        self.get_list method_sym.to_s
      elsif LIST_ACTIONS.include?(method_sym.to_s.pluralize.to_sym)
        self.get_item method_sym.to_s.pluralize, arguments.first
      elsif
        super
      end
    end
    
    private
      def self.get_list list_type
        url = URI.parse("http://api.comicvine.com/#{list_type}/?api_key=#{@@key}&format=json")
        resp = Net::HTTP.get(url)
        JSON.parse(resp)['results']
      end
      
      def self.get_item item_type, id
        url = URI.parse("http://api.comicvine.com/#{item_type}/#{id}/?api_key=#{@@key}&format=json")
        resp = Net::HTTP.get(url)
        JSON.parse(resp)['results'].first
      end
  end
end
