require 'spec_helper'

describe PagesController do
  render_views

  before(:each) do
    @base_title = "lennylonglegs"
  end

  describe "GET 'about'" do
    it "should be successful" do
      get 'about'
      response.should be_success
    end
  end

  it "should have the right title" do
    get 'about'
    response.should have_selector("title",
                                  :content => @base_title + " | About")
  end

end
