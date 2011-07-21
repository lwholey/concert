class PagesController < ApplicationController
  def home
    if (1 == 0) then
      @title = "Home"
    else
      @title = "Homey"
    end
  end

  def contact
    @title = "Contact"
  end

  def about
    @title = "About"
  end
  
end
