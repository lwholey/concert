require 'spec_helper'

# Specs in this file have access to a helper object that includes
# the ResultsHelper. For example:
#
# describe ResultsHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       helper.concat_strings("this","that").should == "this that"
#     end
#   end
# end
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
end
