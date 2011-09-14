
class UsersController < ApplicationController
  include UsersHelper

  def new    
    @user = User.new
    @title = "Home"
  end

  def update
    create
  end

  def create
    puts params[:user]
    @user = User.new(params[:user])
    
    puts("@user.city = #{@user.city}")
    puts("@user.dates = #{@user.dates}")
    puts("@user.keywords = #{@user.keywords}")
    
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
    @user = User.find(params[:id])
    puts "found #{@user.results.count} results"
    @results = @user.results.paginate(:page => params[:page])
    @title = "Results"
  end

end
