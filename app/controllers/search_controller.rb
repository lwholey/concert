class SearchController < ApplicationController
  # maximum number of bands to find tracks for
  $DEFAULT_LOCATION = "Boston, MA"

  def new    
    @search = Search.new
    @title = "Enter Web Page"
  end

  def create
    @search = Search.new(params[:search])
  end

end
