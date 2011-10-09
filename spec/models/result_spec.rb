# == Schema Information
#
# Table name: results
#
#  id            :integer         primary key
#  name          :string(255)
#  date_string   :string(255)
#  venue         :string(255)
#  band          :string(255)
#  track_name    :string(255)
#  track_spotify :string(255)
#  details_url   :string(255)
#  created_at    :timestamp
#  updated_at    :timestamp
#  user_id       :integer
#  you_tube_url  :string(255)
#

require 'spec_helper'

describe Result do

  before(:each) do
    @user = Factory(:user)
    @attr = { 
      :name => "Lenny Live At The Paramount",
      :date_string => "Sunday Aug 24, 2011 at 7PM",
      :venue => "Paramount Theater",
      :band => "Lenny and the Long Legs",
      :track_name => "Sweet Home Pennyslyania",
      :track_spotify => "5qtkWmheqR1COnUvA9UP7r",
      :details_url => "www.lennylonglegs.com"
    }
  end

  it "should create a new instance given valid attributes" do
    @user.results.create!(@attr)
  end

  describe "validations" do
    it "should require a user_id" do
      Result.new(@attr).should_not be_valid
    end
  end

  describe "user associations" do
    before(:each) do
      @result = @user.results.create(@attr)
    end

    it "should have a user attribute" do
      @result.should respond_to(:user)
    end

    it "should have the right associated user" do
      @result.user_id.should == @user.id
      @result.user.should == @user
    end
  end

end
