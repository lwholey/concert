class PagesController < ApplicationController

  def about
    @title = "About"
    @user = User.new
  end
  
end
