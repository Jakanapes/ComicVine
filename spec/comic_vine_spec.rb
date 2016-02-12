require 'spec_helper'
describe ComicVine do
  before(:all) do
    ComicVine::API.key = "some_api_key"
  end
  
  specify { ComicVine::API.key.should == "some_api_key" }
  
  context "when has invalid api key" do
    it "should get a CVError" do
      WebMock.allow_net_connect!
      lambda { ComicVine::API.issues }.should raise_error(ComicVine::CVError)
      WebMock.disable_net_connect!
    end
  end
  
  context "when has valid api key" do
    before { stub_request(:get, "http://comicvine.gamespot.com/api/types/").with(:query => {:format => 'json', :api_key => ComicVine::API.key}, :headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).to_return(:status => 200, :body => TYPES_BODY, :headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}) }
    
    describe "invalid method" do
      it "should raise NoMethodError" do
        lambda { ComicVine::API.something }.should raise_error(NoMethodError)
      end
    end
    
    describe "types_detail" do
      before { @types_detail = ComicVine::API.find_detail "issue" }
      subject { @types_detail }
      
      specify { @types_detail["list_resource_name"].should == "issues" }
      specify { @types_detail["detail_resource_name"].should == "issue" }
    end
    
    describe "types_list" do
      before { @types_list = ComicVine::API.find_list "issues" }
      subject { @types_list }
      
      specify { @types_list["list_resource_name"].should == "issues" }
      specify { @types_list["detail_resource_name"].should == "issue" }
    end
    
    describe "ComicVine search" do
      before do
        stub_request(:get, "http://comicvine.gamespot.com/api/search/").with(:query => {:format => 'json', :api_key => ComicVine::API.key, :limit => 1, :resources => "volume", :query => "gizmo"}, :headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).to_return(:status => 200, :body => SEARCH_BODY_1, :headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'})
        stub_request(:get, "http://comicvine.gamespot.com/api/search/").with(:query => {:format => 'json', :api_key => ComicVine::API.key, :limit => 1, :page => 1, :resources => "volume", :query => "gizmo"}, :headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).to_return(:status => 200, :body => SEARCH_BODY_1, :headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'})
        stub_request(:get, "http://comicvine.gamespot.com/api/search/").with(:query => {:format => 'json', :api_key => ComicVine::API.key, :limit => 1, :page => 2, :resources => "volume", :query => "gizmo"}, :headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).to_return(:status => 200, :body => SEARCH_BODY_2, :headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'})
        @results = ComicVine::API.search "volume", "gizmo", {:limit => 1}
      end
      subject { @results }
      
      it { should be_a_kind_of ComicVine::CVSearchList }
      it { should respond_to("total_count", "offset", "limit", "resource", "query")}
      specify { @results.first.should be_a_kind_of ComicVine::CVObject }
      specify { @results.first.should == @results.last }
      specify { @results.prev_page.should be_nil }
      
      context "when on last page" do
        before { @results.next_page }
        
        specify { @results.should be_a_kind_of ComicVine::CVSearchList }
        specify { @results.next_page.should be_nil }
        it "should update the list on prev_page" do
          @results.prev_page
          @results.should be_a_kind_of ComicVine::CVSearchList
        end
      end
      
      it "should fetch the full CVObject" do
        stub_request(:get, "http://comicvine.gamespot.com/api/volume/4050-24708/").with(:query => {:format => 'json', :api_key => ComicVine::API.key}, :headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).to_return(:status => 200, :body => VOLUME_BODY, :headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'})
        vol = @results.first.fetch
        vol.should be_a_kind_of ComicVine::CVObject
      end
    end
    
    describe "ComicVine list" do
      before do
        stub_request(:get, "http://comicvine.gamespot.com/api/issues/").with(:query => {:format => 'json', :api_key => ComicVine::API.key}, :headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).to_return(:status => 200, :body => ISSUES_BODY_1, :headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'})
        stub_request(:get, "http://comicvine.gamespot.com/api/issues/").with(:query => {:format => 'json', :api_key => ComicVine::API.key, :limit => 2, :offset => 0}, :headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).to_return(:status => 200, :body => ISSUES_BODY_1, :headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'})
        stub_request(:get, "http://comicvine.gamespot.com/api/issues/").with(:query => {:format => 'json', :api_key => ComicVine::API.key, :limit => 2, :offset => 2}, :headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).to_return(:status => 200, :body => ISSUES_BODY_2, :headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'})
        @issues = ComicVine::API.issues
      end
      subject { @issues }
      
      it { should be_a_kind_of ComicVine::CVList }
      it { should respond_to("total_count", "offset", "limit", "resource")}
      specify { @issues.prev_page.should be_nil }
      
      context "when on last page" do
        before { @issues.next_page }
        
        specify { @issues.should be_a_kind_of ComicVine::CVList }
        specify { @issues.next_page.should be_nil }
        it "should update the list on prev_page" do
          @issues.prev_page
          @issues.should be_a_kind_of ComicVine::CVList
        end
      end
    end
    
    describe "ComicVine detail" do
      before do
        stub_request(:get, "http://comicvine.gamespot.com/api/issue/4000-145830/").with(:query => {:format => 'json', :api_key => ComicVine::API.key}, :headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).to_return(:status => 200, :body => ISSUE_BODY, :headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'})
        @issue = ComicVine::API.issue 145830
      end
      subject { @issue }
      
      it { should be_a_kind_of ComicVine::CVObject }
      it { should respond_to("site_detail_url", "publish_year")}
      specify { lambda { @issue.something }.should raise_error(NoMethodError) }
      specify { lambda { @issue.get_something }.should raise_error(NoMethodError) }
      
      it "should have a detail and list association" do
        stub_request(:get, "http://comicvine.gamespot.com/api/volume/4050-24708/").with(:query => {:format => 'json', :api_key => ComicVine::API.key}, :headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).to_return(:status => 200, :body => VOLUME_BODY, :headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'})
        vol = @issue.get_volume
        vol.should be_a_kind_of ComicVine::CVObject
        iss = vol.get_issues
        iss.should be_a_kind_of Array
        iss.first.should be_a_kind_of ComicVine::CVObject
      end
    end
  end
end
