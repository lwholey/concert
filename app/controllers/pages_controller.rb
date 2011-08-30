class PagesController < ApplicationController
  def classicsearch
    @title = "Classic Search"
  end
  
  def home
    @title = "Home"
  end

  def contact
    @title = "Contact"
  end

  def about
    @title = "About"
  end
  
end
