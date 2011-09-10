# == Schema Information
#
# Table name: users
#
#  id         :integer         not null, primary key
#  created_at :datetime
#  updated_at :datetime
#  dates      :string(255)
#  city       :string(255)
#  keywords   :string(255)
#  pageNumber :integer
#

require 'spec_helper'

describe User do
  #pending "add some examples to (or delete) #{__FILE__}"
  
  before(:each) do
    @attr = { :dates => "today", 
              :city => "Boston",
              :keywords => "jazz",
            }
  end
 
  it "should create a new instance given valid attributes" do
    User.create!(@attr)
  end
  
  describe "results association" do

    before(:each) do
      @user = User.create(@attr)
      @r1 = Factory(:result, :user => @user, :track_spotify => "something")
      @r2 = Factory(:result, :user => @user, :track_spotify => "")
    end

    it "should have a results attribute" do
      @user.should respond_to(:results)
    end

    it "should have the right results in the right order" do
      @user.results.should == [@r1, @r2]
    end

    it "should destroy associated results" do
      @user.destroy
      [@r1, @r2].each do |result|
        Result.find_by_id(result.id).should be_nil
      end
    end
    
  end
 
=begin
  it "should require a search criteria" do
    no_field_user = User.new(@attr.merge(:dates => "", :city => "", :keywords => "Red Rocks"))
    no_field_user.should_not be_valid
  end
=end

end
