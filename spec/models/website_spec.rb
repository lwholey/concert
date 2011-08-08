require File.dirname(__FILE__) + '/../spec_helper'

describe Website do
  it "should be valid" do
    Website.new.should be_valid
  end
end
