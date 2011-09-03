class PagesController < ApplicationController
 
  def contact
    @title = "Contact"
    @user = User.new
  end

  def about
    @title = "About"
    @user = User.new
  end
  
end
