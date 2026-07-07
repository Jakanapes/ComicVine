module ComicVine
  class CVList
    include Enumerable
    
    attr_reader :total_count
    attr_reader :page_count
    attr_reader :offset
    attr_reader :limit
    attr_reader :cvos
    
    def initialize(resp)      
      @total_count = resp['number_of_total_results']
      @page_count = resp['number_of_page_results']
      @offset = resp['offset']
      @limit = resp['limit']
    end
    
    def each
      @cvos.each { |c| yield c }
    end
    
    def last
      @cvos.last
    end
    
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
  
  class CVObjectList < CVList
    attr_reader :resource

    def initialize(resp, resc, opts={})
      super(resp)

      @resource = resc
      @opts = opts || {}
      @cvos = resp['results'].map{ |r| ComicVine::CVObject.new(r)}
    end

    def next_page
      return nil if (@offset + @page_count) >= @total_count
      update_ivals(ComicVine::API.send(@resource, @opts.merge(:limit => @limit, :offset => (@offset + @limit))))
      self
    end

    def prev_page
      return nil if @offset == 0
      update_ivals(ComicVine::API.send(@resource, @opts.merge(:limit => @limit, :offset => [@offset - @limit, 0].max)))
      self
    end
  end

  class CVSearchList < CVList
    attr_reader :resource
    attr_reader :query

    def initialize(resp, resc, query, opts={})
      super(resp)

      @resource = resc
      @query = query
      @opts = opts || {}
      @cvos = resp['results'].map{ |r| ComicVine::CVObject.new(r)}
    end

    def next_page
      return nil if (@offset + @page_count) >= @total_count
      update_ivals(ComicVine::API.search(@resource, @query, @opts.merge(:limit => @limit, :page => page + 1)))
      self
    end

    def prev_page
      return nil if @offset == 0
      update_ivals(ComicVine::API.search(@resource, @query, @opts.merge(:limit => @limit, :page => page - 1)))
      self
    end
  end
end