require "comic_vine/version"
require "net/http"
require "multi_json"
require "cgi"

module ComicVine
  
  class CVError < StandardError
  end
  
  class API
    @@key = nil
    
    @@types = nil
    @@last_type_check = nil
    
    @@API_BASE_URL = "https://comicvine.gamespot.com/api/"

    class << self
      def search res, query, opts={}
        opts[:resources] = res.gsub " ", ""
        opts[:query] = CGI::escape query
        resp = hit_api(build_base_url("search"), build_query(opts))
        ComicVine::CVSearchList.new(resp, res, query)
      end
    
      def find_list type
        types.find { |t| t['list_resource_name'] == type }
      end
    
      def find_detail type
        types.find { |t| t['detail_resource_name'] == type }
      end
    
      def method_missing(method_sym, *arguments, &block)
        if find_list(method_sym.to_s)
          get_list method_sym.to_s, arguments.first
        elsif find_detail(method_sym.to_s)
          get_details method_sym.to_s, *arguments
        elsif
          super
        end
      end
    
      def key
        @@key
      end
    
      def key= key
        @@key = key
      end
    
      def types
        if @@types.nil? || (@@last_type_check + (4 *60 *60)) < Time.now
          @@last_type_check = Time.now
          @@types = hit_api(build_base_url('types'))['results']
        end
        @@types
      end

      def get_list list_type, opts=nil
        resp = hit_api(build_base_url(list_type), build_query(opts))
        ComicVine::CVObjectList.new(resp, list_type)
      end
  
      def get_details item_type, id, opts=nil
        resp = hit_api(build_base_url("#{item_type}/#{find_detail(item_type)['id']}-#{id}"), build_query(opts))
        ComicVine::CVObject.new(resp['results'])
      end
      
      def get_details_by_url url
        resp = hit_api(url)
        ComicVine::CVObject.new(resp['results'])
      end
    
      private
        def hit_api base_url, query=""
          url = base_url+"?format=json&api_key=#{@@key}"+query
          uri = URI.parse(url)
          resp = Net::HTTP.get(uri)
          presp = MultiJson.load(resp)
          raise CVError, presp['error'] unless presp['status_code'] == 1
          presp
        end
      
        def build_base_url action
          @@API_BASE_URL+action+"/"
        end
        
        def build_query opts=nil
          query = ''
          if !opts.nil? && !opts.empty?
            opts.each do |k,v|
              query << "&#{k.to_s}=#{v}"
            end
          end
          query
        end

    end
  end
end

require 'comic_vine/cv_object'
require 'comic_vine/cv_list'
