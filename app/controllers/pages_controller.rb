class PagesController < ApplicationController
  
  def initialize()
    @i = 1
  end
  
  def home
    @i = @i + 1
    @var1 = @i
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
