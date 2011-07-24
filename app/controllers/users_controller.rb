class UsersController < ApplicationController
  require 'nokogiri'
  require 'mechanize'
  require 'open-uri'
    
  def new
    @user = User.new
    @title = "Enter Web Page"
  end

  def create
    @user = User.new(params[:user])
    # Get bands from web page
    parseBands
    
    if @user.save
      redirect_to "/entry"
    else
      redirect_to "/entry"
    end
  end

  def parseBands
    url = @user.name
    doc = Nokogiri::HTML(open(url))

    a = Array.new
    i = 0
    doc.css(".event-list-title").each do |concert|
      a[i] = concert.text.chomp.gsub(/\r\n/,"")
      flash[:success] = "Bands found: #{a}"
      i = i + 1
    end
    
    if (i == 0)
      flash[:success] = "No Bands found"
    end
  end

end
