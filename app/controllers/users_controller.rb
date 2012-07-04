
class UsersController < ApplicationController
  include UsersHelper
  EVENTS_PER_PAGE = 5
  EVENTS_PER_PAGE_SMARTPHONE = 1

  def new    
    @user = User.new
    @title = "Home"
  end

  def create
    @user = User.new(params[:user])
    
    if @user.save
      get_results @user
      redirect_to @user
    else
      @title = "Home"
      render 'new'
    end

  end

  def show
    if (client_browser_name == "notMobile")
      per_page = EVENTS_PER_PAGE
    else
      per_page = EVENTS_PER_PAGE_SMARTPHONE
    end
    
    @user = User.find(params[:id])
    @results = @user.results.paginate(:page => params[:page], :per_page => per_page, :order => 'id')
    @title = "Results"
  end

end
