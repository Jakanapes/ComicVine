require 'spec_helper'

RSpec.describe ComicVine do
  before(:all) do
    ComicVine::API.key = "some_api_key"
  end

  specify { expect(ComicVine::API.key).to eq("some_api_key") }

  context "when has invalid api key" do
    before do
      # Reset the cached types list so the request is actually made
      ComicVine::API.class_variable_set(:@@types, nil)
      stub_request(:get, "https://comicvine.gamespot.com/api/types/").with(:query => {:format => 'json', :api_key => ComicVine::API.key}).to_return(:status => 200, :body => ERROR_BODY)
    end

    it "raises a CVError" do
      expect { ComicVine::API.issues }.to raise_error(ComicVine::CVError, "Invalid API Key")
    end
  end

  context "when has valid api key" do
    before do
      ComicVine::API.class_variable_set(:@@types, nil)
      stub_request(:get, "https://comicvine.gamespot.com/api/types/").with(:query => {:format => 'json', :api_key => ComicVine::API.key}).to_return(:status => 200, :body => TYPES_BODY)
    end

    describe "invalid method" do
      it "raises NoMethodError" do
        expect { ComicVine::API.something }.to raise_error(NoMethodError)
      end
    end

    describe "get_details with an unknown type" do
      it "raises a CVError naming the type" do
        expect { ComicVine::API.get_details("bogus", 1) }.to raise_error(ComicVine::CVError, /bogus/)
      end
    end

    describe "build_query" do
      it "URL-encodes values" do
        expect(ComicVine::API.send(:build_query, {:filter => "name:gizmo & friends"})).to eq("&filter=name%3Agizmo+%26+friends")
      end

      it "returns an empty string for nil or empty opts" do
        expect(ComicVine::API.send(:build_query, nil)).to eq("")
        expect(ComicVine::API.send(:build_query, {})).to eq("")
      end
    end

    describe "types_detail" do
      before { @types_detail = ComicVine::API.find_detail "issue" }
      subject { @types_detail }

      specify { expect(@types_detail["list_resource_name"]).to eq("issues") }
      specify { expect(@types_detail["detail_resource_name"]).to eq("issue") }
    end

    describe "types_list" do
      before { @types_list = ComicVine::API.find_list "issues" }
      subject { @types_list }

      specify { expect(@types_list["list_resource_name"]).to eq("issues") }
      specify { expect(@types_list["detail_resource_name"]).to eq("issue") }
    end

    describe "ComicVine search" do
      before do
        stub_request(:get, "https://comicvine.gamespot.com/api/search/").with(:query => {:format => 'json', :api_key => ComicVine::API.key, :limit => 1, :resources => "volume", :query => "gizmo"}).to_return(:status => 200, :body => SEARCH_BODY_1)
        stub_request(:get, "https://comicvine.gamespot.com/api/search/").with(:query => {:format => 'json', :api_key => ComicVine::API.key, :limit => 1, :page => 1, :resources => "volume", :query => "gizmo"}).to_return(:status => 200, :body => SEARCH_BODY_1)
        stub_request(:get, "https://comicvine.gamespot.com/api/search/").with(:query => {:format => 'json', :api_key => ComicVine::API.key, :limit => 1, :page => 2, :resources => "volume", :query => "gizmo"}).to_return(:status => 200, :body => SEARCH_BODY_2)
        @results = ComicVine::API.search "volume", "gizmo", {:limit => 1}
      end
      subject { @results }

      it { is_expected.to be_a_kind_of ComicVine::CVSearchList }
      it { is_expected.to respond_to("total_count", "offset", "limit", "resource", "query") }
      specify { expect(@results.first).to be_a_kind_of ComicVine::CVObject }
      specify { expect(@results.first).to eq(@results.last) }
      specify { expect(@results.prev_page).to be_nil }
      specify { expect(@results.next_page).to equal(@results) }

      it "does not mutate the caller's opts hash" do
        opts = {:limit => 1}
        ComicVine::API.search "volume", "gizmo", opts
        expect(opts).to eq({:limit => 1})
      end

      context "when on last page" do
        before { @results.next_page }

        specify { expect(@results).to be_a_kind_of ComicVine::CVSearchList }
        specify { expect(@results.next_page).to be_nil }
        it "updates the list on prev_page" do
          @results.prev_page
          expect(@results).to be_a_kind_of ComicVine::CVSearchList
        end
      end

      it "fetches the full CVObject" do
        stub_request(:get, "https://comicvine.gamespot.com/api/volume/4050-24708/").with(:query => {:format => 'json', :api_key => ComicVine::API.key}).to_return(:status => 200, :body => VOLUME_BODY)
        vol = @results.first.fetch
        expect(vol).to be_a_kind_of ComicVine::CVObject
      end
    end

    describe "ComicVine list" do
      before do
        stub_request(:get, "https://comicvine.gamespot.com/api/issues/").with(:query => {:format => 'json', :api_key => ComicVine::API.key}).to_return(:status => 200, :body => ISSUES_BODY_1)
        stub_request(:get, "https://comicvine.gamespot.com/api/issues/").with(:query => {:format => 'json', :api_key => ComicVine::API.key, :limit => 2, :offset => 0}).to_return(:status => 200, :body => ISSUES_BODY_1)
        stub_request(:get, "https://comicvine.gamespot.com/api/issues/").with(:query => {:format => 'json', :api_key => ComicVine::API.key, :limit => 2, :offset => 2}).to_return(:status => 200, :body => ISSUES_BODY_2)
        @issues = ComicVine::API.issues
      end
      subject { @issues }

      it { is_expected.to be_a_kind_of ComicVine::CVList }
      it { is_expected.to respond_to("total_count", "offset", "limit", "resource") }
      specify { expect(@issues.prev_page).to be_nil }
      specify { expect(@issues.next_page).to equal(@issues) }

      context "when on last page" do
        before { @issues.next_page }

        specify { expect(@issues).to be_a_kind_of ComicVine::CVList }
        specify { expect(@issues.next_page).to be_nil }
        it "updates the list on prev_page" do
          @issues.prev_page
          expect(@issues).to be_a_kind_of ComicVine::CVList
        end
      end
    end

    describe "list pagination with options and a partial last page" do
      before do
        stub_request(:get, "https://comicvine.gamespot.com/api/issues/").with(:query => {:format => 'json', :api_key => ComicVine::API.key, :limit => 2, :filter => "volume:1487"}).to_return(:status => 200, :body => ISSUES_PARTIAL_1)
        stub_request(:get, "https://comicvine.gamespot.com/api/issues/").with(:query => {:format => 'json', :api_key => ComicVine::API.key, :limit => 2, :offset => 0, :filter => "volume:1487"}).to_return(:status => 200, :body => ISSUES_PARTIAL_1)
        stub_request(:get, "https://comicvine.gamespot.com/api/issues/").with(:query => {:format => 'json', :api_key => ComicVine::API.key, :limit => 2, :offset => 2, :filter => "volume:1487"}).to_return(:status => 200, :body => ISSUES_PARTIAL_2)
        @issues = ComicVine::API.issues({:limit => 2, :filter => "volume:1487"})
      end

      it "preserves the original options when paginating" do
        expect(@issues.next_page).to equal(@issues)
        expect(a_request(:get, "https://comicvine.gamespot.com/api/issues/").with(:query => hash_including({"filter" => "volume:1487", "offset" => "2"}))).to have_been_made
      end

      it "refreshes page_count from each response" do
        @issues.next_page
        expect(@issues.page_count).to eq(1)
      end

      it "realigns the offset on prev_page after a partial last page" do
        @issues.next_page
        @issues.prev_page
        expect(@issues.offset).to eq(0)
      end

      it "returns nil at both boundaries" do
        expect(@issues.prev_page).to be_nil
        @issues.next_page
        expect(@issues.next_page).to be_nil
      end
    end

    describe "ComicVine detail" do
      before do
        stub_request(:get, "https://comicvine.gamespot.com/api/issue/4000-145830/").with(:query => {:format => 'json', :api_key => ComicVine::API.key}).to_return(:status => 200, :body => ISSUE_BODY)
        @issue = ComicVine::API.issue 145830
      end
      subject { @issue }

      it { is_expected.to be_a_kind_of ComicVine::CVObject }
      it { is_expected.to respond_to("site_detail_url", "publish_year") }
      it { is_expected.to respond_to("get_volume") }
      specify { expect { @issue.something }.to raise_error(NoMethodError) }
      specify { expect { @issue.get_something }.to raise_error(NoMethodError) }
      specify { expect(@issue.get_id).to eq(145830) }

      it "has a detail and list association" do
        stub_request(:get, "https://comicvine.gamespot.com/api/volume/4050-24708/").with(:query => {:format => 'json', :api_key => ComicVine::API.key}).to_return(:status => 200, :body => VOLUME_BODY)
        vol = @issue.get_volume
        expect(vol).to be_a_kind_of ComicVine::CVObject
        iss = vol.get_issues
        expect(iss).to be_a_kind_of Array
        expect(iss.first).to be_a_kind_of ComicVine::CVObject
      end
    end

    describe ComicVine::CVObject do
      it "handles arrays of non-hash values" do
        obj = ComicVine::CVObject.new("things" => [1, 2, 3])
        expect(obj.things).to eq([1, 2, 3])
      end

      it "does not leak attribute readers between instances" do
        ComicVine::CVObject.new("foo" => 1)
        other = ComicVine::CVObject.new("bar" => 2)
        expect(other).not_to respond_to(:foo)
        expect { other.foo }.to raise_error(NoMethodError)
      end
    end
  end
end
