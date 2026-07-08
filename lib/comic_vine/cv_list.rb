# frozen_string_literal: true

module ComicVine
  # Base class for paginated result lists. Carries the count values from the
  # API response (`total_count`, `page_count`, `offset`, `limit`) and includes
  # `Enumerable` over the contained {CVObject}s.
  class CVList
    include Enumerable

    # @return [Integer] total results across all pages
    attr_reader :total_count
    # @return [Integer] results on the current page
    attr_reader :page_count
    # @return [Integer] offset of the current page
    attr_reader :offset
    # @return [Integer] page size
    attr_reader :limit
    # @return [Array<CVObject>] the objects on the current page
    attr_reader :cvos

    # @param resp [Hash] a list response from the API
    def initialize(resp)
      @total_count = resp['number_of_total_results']
      @page_count = resp['number_of_page_results']
      @offset = resp['offset']
      @limit = resp['limit']
    end

    # Yields each {CVObject} on the current page.
    def each(&)
      @cvos.each(&)
    end

    # @return [CVObject, nil] the last object on the current page
    def last
      @cvos.last
    end

    # @return [Integer] the current page number (1-based)
    def page
      (@offset / @limit) + 1
    end

    protected

    def update_ivals(new_cvol)
      @total_count = new_cvol.total_count
      @page_count = new_cvol.page_count
      @offset = new_cvol.offset
      @limit = new_cvol.limit

      @cvos = new_cvol.cvos
    end
  end

  # A paginated list of resources (e.g. from `ComicVine::API.characters`).
  # {#next_page} and {#prev_page} update the list in place, preserving the
  # original options (`:filter`, `:sort`, `:field_list`, ...).
  class CVObjectList < CVList
    # @return [String] the plural resource name this list was fetched from
    attr_reader :resource

    # @param resp [Hash] a list response from the API
    # @param resc [String] the plural resource name
    # @param opts [Hash] the options the list was fetched with
    def initialize(resp, resc, opts = {})
      super(resp)

      @resource = resc
      @opts = opts || {}
      @cvos = resp['results'].map { |r| ComicVine::CVObject.new(r) }
    end

    # Advances to the next page, updating the list in place.
    #
    # @return [CVObjectList, nil] `self`, or `nil` if already on the last page
    # @raise [CVError]
    def next_page
      return nil if (@offset + @page_count) >= @total_count

      update_ivals(ComicVine::API.send(@resource, @opts.merge(:limit => @limit, :offset => (@offset + @limit))))
      self
    end

    # Steps back to the previous page, updating the list in place.
    #
    # @return [CVObjectList, nil] `self`, or `nil` if already on the first page
    # @raise [CVError]
    def prev_page
      return nil if @offset == 0

      update_ivals(ComicVine::API.send(@resource, @opts.merge(:limit => @limit, :offset => [@offset - @limit, 0].max)))
      self
    end
  end

  # A paginated list of search results (from {ComicVine::API.search}).
  class CVSearchList < CVList
    # @return [String] the resource type(s) searched
    attr_reader :resource
    # @return [String] the search query
    attr_reader :query

    # @param resp [Hash] a search response from the API
    # @param resc [String] the resource type(s) searched
    # @param query [String] the search query
    # @param opts [Hash] the options the search was made with
    def initialize(resp, resc, query, opts = {})
      super(resp)

      @resource = resc
      @query = query
      @opts = opts || {}
      @cvos = resp['results'].map { |r| ComicVine::CVObject.new(r) }
    end

    # Advances to the next page of results, updating the list in place.
    #
    # @return [CVSearchList, nil] `self`, or `nil` if already on the last page
    # @raise [CVError]
    def next_page
      return nil if (@offset + @page_count) >= @total_count

      update_ivals(ComicVine::API.search(@resource, @query, @opts.merge(:limit => @limit, :page => page + 1)))
      self
    end

    # Steps back to the previous page of results, updating the list in place.
    #
    # @return [CVSearchList, nil] `self`, or `nil` if already on the first page
    # @raise [CVError]
    def prev_page
      return nil if @offset == 0

      update_ivals(ComicVine::API.search(@resource, @query, @opts.merge(:limit => @limit, :page => page - 1)))
      self
    end
  end
end
