module ComicVine
  class CVObject
    def initialize(args)
      args.each do |k,v|
        self.class.class_eval { attr_accessor k }
        instance_variable_set "@#{k}", v
      end
    end
    
    def method_missing(method_sym, *arguments, &block)
      if method_sym.to_s =~ /^get_(.*)$/
        key = method_sym.to_s.sub "get_", ""
        if instance_variable_defined?("@#{key}")
          item = instance_variable_get("@#{key}")
          if item.kind_of?(Array) && item.first.key?("api_detail_url")
            res = []
            item.each do |i|
              res << ComicVine::API.get_details_by_url(i["api_detail_url"])
            end
            return res
          end
          if item.kind_of?(Hash) && item.key?("api_detail_url")
            return ComicVine::API.get_details_by_url(item["api_detail_url"])
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
end