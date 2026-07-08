# frozen_string_literal: true

module ComicVine
  # Wraps a single resource returned by the API. Every key in the response
  # becomes a reader method; nested resources that carry an `api_detail_url`
  # become {CVObject}s themselves and can be expanded with `get_<key>`.
  class CVObject
    # @param args [Hash] a resource hash from the API response
    def initialize(args)
      args.each do |k, v|
        singleton_class.class_eval { attr_reader k } unless respond_to?(k)
        v.collect! { |i| CVObject.new i } if v.is_a?(Array) && v.first.is_a?(Hash) && v.first.key?("api_detail_url")
        v = CVObject.new v if v.is_a?(Hash) && v.key?("api_detail_url")
        instance_variable_set "@#{k}", v
      end
    end

    # Retrieves the full object from this object's `api_detail_url`.
    #
    # @return [CVObject]
    # @raise [CVError]
    def fetch
      ComicVine::API.get_details_by_url(@api_detail_url)
    end

    # Resolves `get_<key>` calls: fetches the full object(s) behind an
    # association, or returns the plain value if it isn't an association.
    def method_missing(method_sym, *arguments, &)
      if method_sym.to_s =~ /^get_(.*)$/
        key = $1
        if instance_variable_defined?("@#{key}")
          item = instance_variable_get("@#{key}")
          if item.is_a?(Array) && item.first.is_a?(CVObject)
            item.map(&:fetch)
          elsif item.is_a?(CVObject)
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
