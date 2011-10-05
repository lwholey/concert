
class UsersController < ApplicationController
  include UsersHelper
  EVENTS_PER_PAGE = 5
  EVENTS_PER_PAGE_SMARTPHONE = 1

  def new    
    @user = User.new
    @title = "Home"
  end

  def create
    puts params[:user]
    @user = User.new(params[:user])
    
    puts("@user.city = #{@user.city}")
    puts("@user.dates = #{@user.dates}")
    puts("@user.keywords = #{@user.keywords}")
    puts("@user.pageNumber = #{@user.pageNumber}")
    
    if @user.save
     
      # create results
      #

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
    puts "found #{@user.results.count} results"
    @results = @user.results.paginate(:page => params[:page], :per_page => per_page)
    @title = "Results"
  end

end
