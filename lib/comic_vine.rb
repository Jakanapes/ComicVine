require "comic_vine/version"
require "net/http"
require "json"

module ComicVine
  
  class CVError < StandardError  
  end
  
  class API
    @@key = nil
    
    @@types = nil
    @@last_type_check = nil
    
    @@API_BASE_URL = "http://api.comicvine.com/"

    def self.search res, query, opts={}
      resp = hit_api(build_url("search", opts)+"&resources=#{res}&query=#{query}")
      ComicVine::CVSearchList.new(resp, res, query)
    end
    
    def self.find_list type
      types.find { |t| t['list_resource_name'] == type }
    end
    
    def self.find_detail type
      types.find { |t| t['detail_resource_name'] == type }
    end
    
    def self.method_missing(method_sym, *arguments, &block)
      if find_list(method_sym.to_s)
        get_list method_sym.to_s, arguments.first
      elsif find_detail(method_sym.to_s)
        get_details method_sym.to_s, *arguments
      elsif
        super
      end
    end
    
    def self.key
      @@key
    end
    
    def self.key= key
      @@key = key
    end
    
    def self.types
      if @@types.nil? || (@@last_type_check + (4 *60 *60)) > Time.now
        @@last_type_check = Time.now
        @@types = hit_api(build_url('types'))['results']
      end
      @@types
    end
  
    def self.get_list list_type, opts=nil
      resp = hit_api(build_url(list_type, opts))
      ComicVine::CVObjectList.new(resp, list_type)
    end
    
    def self.get_details item_type, id, opts=nil
      resp = hit_api(build_url("#{item_type}/#{id}", opts))
      ComicVine::CVObject.new(resp['results'])
    end
    
    def self.hit_api url
      uri = URI.parse(url)
      resp = Net::HTTP.get(uri)
      presp = JSON.parse(resp)
      raise CVError, presp['error'] unless presp['status_code'] == 1
      presp
    end
    
    def self.build_url action, opts=nil
      query = ''
      if !opts.nil? && !opts.empty?
        opts.each do |k,v|
          query << "&#{k.to_s}=#{v}"
        end
      end
      @@API_BASE_URL+action+"/?format=json&api_key=#{@@key}#{query}"
    end

    private_class_method :types
    private_class_method :get_list
    private_class_method :get_details
    private_class_method :hit_api
    private_class_method :build_url
  end
end

require 'comic_vine/cv_object'
require 'comic_vine/cv_list'
