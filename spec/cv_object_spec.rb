require 'spec_helper'
describe ComicVine::CVObject do
  it "should inialize instance variables from a hash" do
    h = {'something' => 'something', 'blah' => 'blah', 'number' => 100}
    cvo = ComicVine::CVObject.new h
    cvo.something.should == 'something'
    cvo.blah.should == 'blah'
    cvo.number.should == 100
  end
end