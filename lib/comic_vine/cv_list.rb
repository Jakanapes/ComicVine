module ComicVine
  class CVList
    include Enumerable
    
    attr_reader :total_count
    attr_reader :offset
    attr_reader :limit
    attr_reader :cvos
    
    def initialize(resp)      
      @total_count = resp['number_of_total_results']
      @offset = resp['offset']
      @limit = resp['limit']
    end
    
    def each
      @cvos.each { |c| yield c }
    end
    
    def last
      @cvos.last
    end
    
    protected
      def update_ivals(new_cvol)
        @total_count = new_cvol.total_count
        @offset = new_cvol.offset
        @limit = new_cvol.limit

        @cvos = new_cvol.cvos
      end
  end
  
  class CVObjectList < CVList
    attr_reader :resource
    
    def initialize(resp, resc)      
      super(resp)
      
      @resource = resc
      @cvos = resp['results'].map{ |r| ComicVine::CVObject.new(r)}
    end
    
    def next_page
      return nil if (@offset + count) == @total_count
      update_ivals(ComicVine::API.send(@resource, {:limit => @limit, :offset => (@offset + count)}))
    end
    
    def prev_page
      return nil if @offset == 0
      update_ivals(ComicVine::API.send(@resource, {:limit => @limit, :offset => (@offset - count)}))
    end
  end
  
  class CVSearchList < CVList
    attr_reader :resource
    attr_reader :query
    
    def initialize(resp, resc, query)      
      super(resp)
      
      @resource = resc
      @query = query
      @cvos = resp['results'].map{ |r| ComicVine::CVObject.new(r)}
    end
    
    def next_page
      return nil if (@offset + count) == @total_count
      update_ivals(ComicVine::API.search(@resource, @query, {:limit => @limit, :offset => (@offset + count)}))
    end
    
    def prev_page
      return nil if @offset == 0
      update_ivals(ComicVine::API.search(@resource, @query, {:limit => @limit, :offset => (@offset - count)}))
    end
  end
end