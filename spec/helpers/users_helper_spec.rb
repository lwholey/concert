require 'spec_helper'
require 'pry'

describe UsersHelper do
  
  describe "#get_spotify_tracks" do
    
  end
  
  describe "#get_track_info" do
    
  end
  
  describe "#create_artist_url" do
    r = UsersHelper.create_artist_url('the allman brothers')
    r.should == 'http://ws.spotify.com/search/1/artist?q=the%20allman%20brothers'
  end
  
  describe "#get_artist" do
    
  end
  
  describe "#get_album" do
    
  end
  
  describe "#get_track_code" do
    
  end

  describe "#available_in_US?" do

  end
  
  describe "#track_available?" do

  end

  describe "#show_you_tube_video" do
    
  end
 
  describe "between_two_strings" do
    r = UsersHelper.between_two_strings("<artist> rockabilies </artist>","<artist>","</artist>")
    r.should == ' rockabilies '
  end
  
end
