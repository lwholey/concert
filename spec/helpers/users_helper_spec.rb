require 'spec_helper'
require 'pry'
require 'vcr'

def allman_brothers
  'the allman brothers'
end

def allman_brothers_url
  'http://ws.spotify.com/search/1/artist?q=the%20allman%20brothers'
end

def artist
  'spotify:artist:4wQ3PyMz3WwJGI5uEqHUVR'
end

def album
  "spotify:album:6c7Tr0ltE8TX2x3loUeFgW"
end

def track
  'spotify:track:54QvsT7OAOhnG2P2pzjx9x'
end

describe UsersHelper do
  
  describe "#get_spotify_tracks" do
    results = [Factory(:result, :band => allman_brothers),
              Factory(:result, :band => 'coldplay')]
    VCR.use_cassette('get_spotify_tracks') do
      r = UsersHelper.get_spotify_tracks(results)
      r.should == "spotify:track:54QvsT7OAOhnG2P2pzjx9x spotify:track:3vCzHYgSjMuGjFMfJSCx4c"
    end
  end
  
  describe "#get_track_info" do
    VCR.use_cassette('get_track_info') do
      r = UsersHelper.get_track_info(allman_brothers)
      r.should == track
    end
  end

  describe "#create_artist_url" do
    r = UsersHelper.create_artist_url(allman_brothers)
    r.should == allman_brothers_url
  end
  
  describe "#get_artist" do
    VCR.use_cassette('get_artist') do
      r = UsersHelper.get_artist(allman_brothers_url)
      r.should == artist
    end
  end
  
  describe "#get_album" do
    VCR.use_cassette('get_album') do
      r = UsersHelper.get_album(artist)
      r.should == album
    end
  end

  describe "#get_track_code" do
    VCR.use_cassette('get_track_code') do
      r = UsersHelper.get_track_code(album)
      r.should == track
    end
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
