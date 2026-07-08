require "comic_vine/version"
require "net/http"
require "openssl"
require "multi_json"
require "cgi"

module ComicVine

  # Base class for all errors raised by this gem.
  class CVError < StandardError
  end

  # Raised when the ComicVine API answers with a non-success status_code
  # (e.g. invalid API key, object not found).
  class CVAPIError < CVError
  end

  # Raised when the connection fails or times out after all retries.
  class CVConnectionError < CVError
  end

  # Raised when the server answers with a non-2xx HTTP status.
  class CVHTTPError < CVError
    attr_reader :status

    def initialize(message, status = nil)
      @status = status
      super(message)
    end
  end

  # Raised on HTTP 420/429 once retries are exhausted. ComicVine rate-limits
  # to roughly 200 requests per resource per hour.
  class CVRateLimitError < CVHTTPError
  end

  # Raised when the response body is not valid JSON (e.g. an HTML error page).
  class CVParseError < CVError
  end

  class API
    API_BASE_URL = "https://comicvine.gamespot.com/api/"
    TYPES_CACHE_TTL = 4 * 60 * 60
    RETRYABLE_STATUS_CODES = [420, 429, 500, 502, 503, 504].freeze
    RETRYABLE_EXCEPTIONS = [
      Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET, Errno::ECONNREFUSED,
      Errno::ETIMEDOUT, SocketError, EOFError, OpenSSL::SSL::SSLError
    ].freeze

    @key = nil
    @types = nil
    @last_type_check = nil
    @types_mutex = Mutex.new

    @open_timeout = 10
    @read_timeout = 30
    @max_retries = 3
    @retry_base_delay = 1.0

    class << self
      attr_accessor :key
      attr_accessor :open_timeout, :read_timeout
      attr_accessor :max_retries, :retry_base_delay
      attr_writer :user_agent

      def user_agent
        @user_agent ||= "comic_vine gem/#{ComicVine::VERSION} (Ruby/#{RUBY_VERSION})"
      end

      def search res, query, opts={}
        query_opts = opts.merge(:resources => res.gsub(" ", ""), :query => query)
        resp = hit_api(build_base_url("search"), build_query(query_opts))
        ComicVine::CVSearchList.new(resp, res, query, opts)
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
        else
          super
        end
      end

      def respond_to_missing?(method_sym, include_private = false)
        name = method_sym.to_s
        return true if find_list(name) || find_detail(name)
        super
      rescue CVError
        super
      end

      def types
        @types_mutex.synchronize do
          if @types.nil? || (@last_type_check + TYPES_CACHE_TTL) < Time.now
            begin
              @types = hit_api(build_base_url('types'))['results']
              @last_type_check = Time.now
            rescue CVHTTPError => e
              raise e.class.new("Could not load the ComicVine /types/ list (needed to resolve API methods): #{e.message}", e.status)
            rescue CVError => e
              raise e.class, "Could not load the ComicVine /types/ list (needed to resolve API methods): #{e.message}"
            end
          end
          @types
        end
      end

      # Clears the cached /types/ list (mainly useful in tests).
      def reset_types_cache!
        @types_mutex.synchronize do
          @types = nil
          @last_type_check = nil
        end
      end

      def get_list list_type, opts=nil
        resp = hit_api(build_base_url(list_type), build_query(opts))
        ComicVine::CVObjectList.new(resp, list_type, opts || {})
      end

      def get_details item_type, id, opts=nil
        detail = find_detail(item_type)
        raise CVError, "Unknown ComicVine resource type: #{item_type}" if detail.nil?
        resp = hit_api(build_base_url("#{item_type}/#{detail['id']}-#{id}"), build_query(opts))
        ComicVine::CVObject.new(resp['results'])
      end

      def get_details_by_url url
        resp = hit_api(url)
        ComicVine::CVObject.new(resp['results'])
      end

      private
        def hit_api base_url, query=""
          uri = URI.parse("#{base_url}?format=json&api_key=#{@key}#{query}")
          response = fetch_with_retries(uri)
          parse_body(response.body)
        end

        def fetch_with_retries uri
          attempt = 0
          loop do
            attempt += 1
            begin
              response = perform_request(uri)
            rescue *RETRYABLE_EXCEPTIONS => e
              if attempt <= max_retries
                sleep retry_delay(attempt)
                next
              end
              raise CVConnectionError, "Connection to #{uri.host} failed after #{attempt} attempts: #{e.class}: #{e.message}"
            end

            code = response.code.to_i
            return response if (200..299).cover?(code)

            if RETRYABLE_STATUS_CODES.include?(code) && attempt <= max_retries
              sleep retry_delay(attempt, response)
              next
            end

            if code == 420 || code == 429
              raise CVRateLimitError.new("ComicVine rate limit hit (HTTP #{code}) and still throttled after #{attempt} attempts. The API allows roughly 200 requests per resource per hour.", code)
            end
            raise CVHTTPError.new("ComicVine API returned HTTP #{code} #{response.message}".strip, code)
          end
        end

        def perform_request uri
          Net::HTTP.start(uri.host, uri.port,
                          :use_ssl => uri.scheme == "https",
                          :open_timeout => open_timeout,
                          :read_timeout => read_timeout) do |http|
            request = Net::HTTP::Get.new(uri)
            request["User-Agent"] = user_agent
            request["Accept"] = "application/json"
            http.request(request)
          end
        end

        def retry_delay attempt, response = nil
          if response && response["Retry-After"].to_s =~ /\A\d+\z/
            response["Retry-After"].to_i
          else
            retry_base_delay * (2 ** (attempt - 1))
          end
        end

        def parse_body body
          presp = begin
            MultiJson.load(body)
          rescue MultiJson::ParseError => e
            raise CVParseError, "ComicVine returned a response that is not valid JSON: #{e.message}"
          end
          raise CVParseError, "ComicVine returned unexpected JSON (expected an object, got #{presp.class})" unless presp.kind_of?(Hash)
          raise CVAPIError, presp['error'] unless presp['status_code'] == 1
          presp
        end

        def build_base_url action
          API_BASE_URL+action+"/"
        end

        def build_query opts=nil
          return '' if opts.nil? || opts.empty?
          opts.map { |k, v| "&#{k}=#{CGI.escape(v.to_s)}" }.join
        end

    end
  end
end

require 'comic_vine/cv_object'
require 'comic_vine/cv_list'
