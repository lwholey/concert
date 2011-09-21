require 'spec_helper'

describe "Users" do
  describe "search" do
    it "should show canned test data" do
      lambda do
        visit search_path
        click_button
        response.should render_template('users/show')
      end.should change(Result, :count).by(2)
    end
  end
end
