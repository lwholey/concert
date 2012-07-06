require 'spec_helper'
require 'pry'

describe UsersHelper do

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
  
  describe "#show_you_tube_video" do
    
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

  describe "#available_in_US" do
    r = UsersHelper.available_in_US("<album href=\'spotify:album:0JXjMq6OTxiLtmDl40al0j\'>\n      <name>I Am the Fun Blame Monster! B-Sides!</name>\n      <artist href=\'spotify:artist:676oR6vRgfSzaBibbPhLhH\'>\n        <name>Menomena</name>\n      </artist>\n      <availability>\n        <territories>AD AE AF AG AI AL AM AN AO AQ AR AS AT AU AW AX AZ BA BB BD BE BF BG BH BI BJ BM BN BO BR BS BT BV BW BY BZ CA CC CD CF CG CH CI CK CL CM CN CO CR CU CV CX CY CZ DE DJ DK DM DO DZ EC EE EG EH ER ES ET FI FJ FK FM FO FR GA GB GD GE GF GG GH GI GL GM GN GP GQ GR GS GT GU GW GY HK HM HN HR HT HU ID IE IL IN IO IQ IR IS IT JM JO JP KE KG KH KI KM KN KP KR KW KY KZ LA LB LC LI LK LR LS LT LU LV LY MA MC MD ME MG MH MK ML MM MN MO MP MQ MR MS MT MU MV MW MX MY MZ NA NC NE NF NG NI NL NO NP NR NU NZ OM PA PE PF PG PH PK PL PM PN PR PS PT PW PY QA RE RO RS RU RW SA SB SC SD SE SG SH SI SJ SK SL SM SN SO SR ST SV SY SZ TC TD TF TG TH TJ TK TL TM TN TO TR TT TV TW TZ UA UG UM US UY UZ VA VC VE VG VI VN VU WF WS YE YT ZA ZM ZW ZZ</territories>\n      </availability>\n    </album>")
    r.should == true
    r = UsersHelper.available_in_US("<album href=\'spotify:album:0JXjMq6OTxiLtmDl40al0j\'>\n      <name>I Am the Fun Blame Monster! B-Sides!</name>\n      <artist href=\'spotify:artist:676oR6vRgfSzaBibbPhLhH\'>\n        <name>Menomena</name>\n      </artist>\n      <availability>\n        <territories>AD AE AF AG AI AL AM AN AO AQ AR AS AT AU AW AX AZ BA BB BD BE BF BG BH BI BJ BM BN BO BR BS BT BV BW BY BZ CA CC CD CF CG CH CI CK CL CM CN CO CR CU CV CX CY CZ DE DJ DK DM DO DZ EC EE EG EH ER ES ET FI FJ FK FM FO FR GA GB GD GE GF GG GH GI GL GM GN GP GQ GR GS GT GU GW GY HK HM HN HR HT HU ID IE IL IN IO IQ IR IS IT JM JO JP KE KG KH KI KM KN KP KR KW KY KZ LA LB LC LI LK LR LS LT LU LV LY MA MC MD ME MG MH MK ML MM MN MO MP MQ MR MS MT MU MV MW MX MY MZ NA NC NE NF NG NI NL NO NP NR NU NZ OM PA PE PF PG PH PK PL PM PN PR PS PT PW PY QA RE RO RS RU RW SA SB SC SD SE SG SH SI SJ SK SL SM SN SO SR ST SV SY SZ TC TD TF TG TH TJ TK TL TM TN TO TR TT TV TW TZ UA UG UM UY UZ VA VC VE VG VI VN VU WF WS YE YT ZA ZM ZW ZZ</territories>\n      </availability>\n    </album>")
    r.should == nil
  end

  describe "track_popularity" do
    r = UsersHelper.track_popularity("<track href=\'spotify:track:5h29TEP9jlapMIieHASs7S\'>\n      <name>Shirt</name>\n      <artist href=\'spotify:artist:676oR6vRgfSzaBibbPhLhH\'>\n        <name>Menomena</name>\n      </artist>\n      <available>true</available>\n      <id type=\'isrc\'>uscgj1158796</id>\n      <disc-number>1</disc-number>\n      <track-number>1</track-number>\n      <length>215.653000</length>\n      <popularity>0.26927</popularity>\n    </track>")
    r.should == 0.26927
  end

  describe "available_track" do
    r = UsersHelper.available_track("<track href=\"spotify:track:5h29TEP9jlapMIieHASs7S\'>\n      <name>Shirt</name>\n      <artist href=\'spotify:artist:676oR6vRgfSzaBibbPhLhH\'>\n        <name>Menomena</name>\n      </artist>\n      <available>true</available>\n      <id type=\'isrc\'>uscgj1158796</id>\n      <disc-number>1</disc-number>\n      <track-number>1</track-number>\n      <length>215.653000</length>\n      <popularity>0.26927</popularity>\n    </track>")
    r.should == true
    r = UsersHelper.available_track("<track href=\"spotify:track:5h29TEP9jlapMIieHASs7S\'>\n      <name>Shirt</name>\n      <artist href=\'spotify:artist:676oR6vRgfSzaBibbPhLhH\'>\n        <name>Menomena</name>\n      </artist>\n      <available>false</available>\n      <id type=\'isrc\'>uscgj1158796</id>\n      <disc-number>1</disc-number>\n      <track-number>1</track-number>\n      <length>215.653000</length>\n      <popularity>0.26927</popularity>\n    </track>")
    r.should == nil
  end
 
  describe "between_two_strings" do
    r = UsersHelper.between_two_strings("<artist> rockabilies </artist>","<artist>","</artist>")
    r.should == ' rockabilies '
  end
  
end
