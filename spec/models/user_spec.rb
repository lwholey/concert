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
require 'pry'
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
      @r1 = Factory(:result, :user => @user)
      @r2 = Factory(:result, :user => @user)
    end

    it "should have a results attribute" do
      @user.should respond_to(:results)
    end

    it "should destroy associated results" do
      @user.destroy
      [@r1, @r2].each do |result|
        Result.find_by_id(result.id).should be_nil
      end
    end
    
  end

  describe "#get_results" do
    
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
    @user = User.new
    @user.set_eventful_inputs
    VCR.use_cassette('call_eventful') do
      r = @user.call_eventful
      r['events']['event'].count.should == 10
    end
  end
  
  describe "#get_echo_nest_keyword" do
    @user = User.create(@attr)
    VCR.use_cassette('get_echo_nest_keyword') do
      r = @user.get_echo_nest_keyword('allman brothers')
      r.should == "blues"
    end
  end
  
  describe "#create_results_for_user" do
    @user = User.create(@attr)
    @user.set_eventful_inputs
    VCR.use_cassette('create_results_for_user') do
      results = @user.call_eventful
      r = @user.create_results_for_user(results)
      r.should == true
      @user.results.count.should == 8
      @user.results[1].band == 'Rick Springfield Concert'
      @user.results[1].venue == 'Main Sreet'
    end
  end
  
  describe "#save_results" do
    
  end
  
  describe "#massage_time" do
    @user = User.create(@attr)
    r = @user.massage_time("2012-07-30 19:00:00")
    r.should == "Mon 7/30 7:00 PM"
  end
  
  describe "#update_results_with_you_tube_url" do
    
  end
  
  describe "#find_text_after" do
    @user = User.create(@attr)
    r = @user.find_text_after('featuring the jay hawks', 'featuring')
    r.should == 'the jay hawks'
  end

  describe "#set_you_tube_url" do
    @user = User.create(@attr)
    r = @user.set_you_tube_url('featuring the jay hawks', false)
    r.should == 'https://gdata.youtube.com/feeds/api/videos?category=Music&q=featuring%2Cthe%2Cjay%2Chawks%2Clive%2Cband&v=2&key=AI39si7SV5n5UyDjSu4HZ92aHlfO-TJ_afBaUyFwSFhIWt46aFBD6KqS7TfGuDZR_a9OUL3A4HtxGMOpAf56WNCAAQz_ptBCbw&alt=atom&orderby=relevance&max-results=10'
  end
  
  describe "#massage_keywords" do
    @user = User.create(@attr)
    r = @user.massage_keywords('  Rock concert   boston', false)
    r.should == 'rock%2Cconcert%2Cboston'
    r = @user.massage_keywords('  Rock concert   boston', true)
    r.should == '%22rock+concert+boston%22'
  end

  describe "#get_video_url" do
    
  end

  describe "#User.remove_accents" do
    # doesn't change a string without accents
    r = User.remove_accents("Bela Fleck")
    r.should == 'Bela Fleck'
    # add testing for a string with an accent
  end

end
