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
end