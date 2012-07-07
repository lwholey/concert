require 'spec_helper'
require 'pry'

describe UsersHelper do
  include UsersHelper

  describe "building a result object" do

    # create two sample events
    before(:each) do
      @results = {  "events" => { "event" => [] }  }

      event = {
        "performers" => { "performer" => {"creator"=>"legalsmith", "id"=>"P1-001-000153086-2", "linker"=>"chuck", "name"=>"Pierce Pettis", "short_bio"=>"singer songwriter", "url"=>"http://eventful.com/performers/pierce-pettis-/P0-001-000153086-2?utm_source=apis&utm_medium=apim&utm_campaign=apic"}},
        "title" => "Pierce Pettis",
        "start_time" => "2012-02-10 20:00:00",
        "venue_name" => "me &amp; thee coffeehouse",
        "url" => "http://eventful.com/marblehead/events/pierce-pettis-connor-garvey-/E0-001-041702648-3?utm_source=apis&utm_medium=apim&utm_campaign=apic"
      }

      @results["events"]["event"] << event
      @results["events"]["event"] << event.merge( "performers" => nil )
    
      @user = Factory(:user)

    end

  end
  
  describe "#get_spotify_tracks" do
    
  end
  
  describe "#get_track_info" do
    
  end
  
  describe "#create_artist_url" do
    
  end
  
  describe "#search_artist" do
    
  end
  
  describe "#lookup_artist" do
    
  end
  
  describe "#lookup_album" do
    
  end
  
  describe "#lookup_album" do
    
  end

  describe "#available_in_US?" do

  end

  describe "#show_you_tube_video" do
    
  end
 
  describe "between_two_strings" do
    r = UsersHelper.between_two_strings("<artist> rockabilies </artist>","<artist>","</artist>")
    r.should == ' rockabilies '
  end
  
end
