# == Schema Information
#
# Table name: users
#
#  id         :integer         primary key
#  created_at :timestamp
#  updated_at :timestamp
#  city       :string(255)
#  keywords   :string(255)
#  pageNumber :integer
#  max_pages  :integer
#  start_date :string(255)
#  end_date   :string(255)
#  sort_by    :string(255)
#

require 'spec_helper'

describe User do
  #pending "add some examples to (or delete) #{__FILE__}"
  
  before(:each) do
    @attr = { :start_date => "11/4/2011",
              :end_date => "11/6/2011",
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
 
  it "should set default search criteria" do
    u = User.new(@attr.merge(:start_date => nil, :end_date => nil, :city => nil, :keywords => nil))
    u.city.should == "usa"
    u.start_date.should == "11/4/2011"
    u.end_date.should == "11/6/2011" 
    u.keywords.should == "concert"
  end

end
