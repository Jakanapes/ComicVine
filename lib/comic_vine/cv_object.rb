module ComicVine
  class CVObject
    def initialize(args)
      args.each do |k,v|
        singleton_class.class_eval { attr_reader k } unless respond_to?(k)
        v.collect! { |i| CVObject.new i } if v.kind_of?(Array) && v.first.kind_of?(Hash) && v.first.key?("api_detail_url")
        v = CVObject.new v if v.kind_of?(Hash) && v.key?("api_detail_url")
        instance_variable_set "@#{k}", v
      end
    end

    def fetch
      ComicVine::API.get_details_by_url(@api_detail_url)
    end

    def method_missing(method_sym, *arguments, &block)
      if method_sym.to_s =~ /^get_(.*)$/
        key = $1
        if instance_variable_defined?("@#{key}")
          item = instance_variable_get("@#{key}")
          if item.kind_of?(Array) && item.first.kind_of?(CVObject)
            item.map { |i| i.fetch }
          elsif item.kind_of?(CVObject)
            item.fetch
          else
            item
          end
        else
          super
        end
      else
        super
      end
    end

    def respond_to_missing?(method_sym, include_private = false)
      method_sym.to_s =~ /^get_(.*)$/ ? instance_variable_defined?("@#{$1}") : super
    end
  end
end
