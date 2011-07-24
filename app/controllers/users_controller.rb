class UsersController < ApplicationController
  require 'nokogiri'
  require 'mechanize'
  require 'open-uri'
    
  def new
    @user = User.new
    @title = "Enter Web Page"
    @var1 ||= 0
  end

  def create
    # @var1 = 1 #this doesn't seem to change the value for very long
    @user = User.new(params[:user])
    # Get bands from web page
    parseBands
    
    if @user.save
    
      #a = Mechanize.new { |agent|
      #  agent.user_agent_alias = 'Mac Safari'
      #  }    
      #flash[:success] = "You sent #{@user.name}! and @var1 = #{@var1}"
      redirect_to "/entry"
    else
      #@title = "Sign up"
      #@user.password = ""
      #@user.password_confirmation = ""
      #render 'new'
      redirect_to "/entry"
    end
  end

  def parseBands
    #flash[:success] = "Yes, You sent #{@user.name}! and @var1 = #{@var1}"
    #url = 'http://thephoenix.com/Boston/Concerts/search/'
    url = @user.name
    doc = Nokogiri::HTML(open(url))

    a = Array.new
    i = 0
    doc.css(".event-list-title").each do |concert|
      a[i] = concert.text.chomp.gsub(/\r\n/,"")
      flash[:success] = "Bands found: #{a}"
      i = i + 1
    end
    
=begin
    a = Array.new
    a[0] = 'this'
    a[1] = 'that'
    flash[:success] = "#{a}"
=end
  end

end
