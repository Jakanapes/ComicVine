require 'spec_helper'
describe ComicVine do
  it "should allow the user to set the API key" do
    ComicVine::API.key = "some_api_key"
    ComicVine::API.key.should == "some_api_key"
  end
  
  it "should raise a ComicVine::CVError on an API call without the key set" do
    expect{ ComicVine::API.issues }.to raise_error(ComicVine::CVError)
  end
end