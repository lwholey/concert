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
  
  before(:each) do
    @attr = { :start_date => "11/4/2011",
              :end_date => "11/6/2011",
              :city => "Boston",
              :keywords => "jazz",
              :sort_by => 'popularity'
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

  describe "#dates_for_eventful" do
    before(:each) do
      @user = User.create(@attr)
    end
    
    it "returns the right dates" do
      r = @user.dates_for_eventful
      r.should == '2011110400-2011110600'
    end
    
    it "returns the same date if second date is in the past" do
      @user.update_attributes(:start_date => '11/4/2011', :end_date => '10/4/2011')
      r = @user.dates_for_eventful
      r.should == '2011110400-2011110400'
    end
    
    it "returns 'future' if date is not in right format" do
      @user.update_attributes(:start_date => '', :end_date => '')
      r = @user.dates_for_eventful
      r.should == 'future'
    end
  end
  
  describe "#set_eventful_inputs" do
    before(:each) do
      @user = User.create(@attr)
    end
    
    it "sets city to usa if city is blank" do
      @user.update_attributes(:city => '')
      @user.set_eventful_inputs
      @user.city.should == 'usa'
    end
    
    it "sets start_date to future if blank" do
      @user.update_attributes(:start_date => '')
      @user.set_eventful_inputs
      @user.start_date.should == 'future'
    end
    
    it "sets end_date to future if blank" do
      @user.update_attributes(:end_date => '')
      @user.set_eventful_inputs
      @user.end_date.should == 'future'
    end
    
    it "sets keywords to concert if blank" do
      @user.update_attributes(:keywords => '')
      @user.set_eventful_inputs
      @user.keywords.should == 'concert'
    end
    
    it "sets pageNumber to 1 if nil" do
      @user.update_attributes(:pageNumber => nil)
      @user.set_eventful_inputs
      @user.pageNumber.should == 1
    end
    
    it "sets sort order and direction correctly when sort by popularity" do
      @user.set_eventful_inputs
      @user.sort_order.should == 'popularity'
      @user.sort_direction.should == 'descending'
    end
    
    it "sets sort order and direction correctly when sort by popularity" do
      @user.update_attributes(:sort_by => 'date')
      @user.set_eventful_inputs
      @user.sort_order.should == 'date'
      @user.sort_direction.should == 'ascending'
    end
  end

  describe "#call_eventful" do
    
  end
  
  describe "#getEchoNestKeyword" do
    
  end
  
  describe "#create_results_for_user" do
    
  end
  
  describe "#save_results" do
    
  end
  
  describe "#message_time" do
    
  end
  
  describe "#update_results_with_you_tube_url" do
    
  end
  
  describe "#find_text_after" do
    
  end

  #many other functions to test

end
