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

  # Parses bands from BostonPhoenix.com
  def parseBands
    begin
      url = @user.name
      logic1 = siteSupported(url)
      if (logic1 == 1)
        doc = Nokogiri::HTML(open(url))
      
        a = Array.new
        i = 0
        doc.css(".event-list-title").each do |concert|
          a[i] = concert.text.chomp.gsub(/\r\n/,"")
          flash[:success] = "Bands found: #{a}"
          i = i + 1
        end

        if (i == 0)
          showNoBands
        end
      
      else
        flash[:success] = "Web site not supported"
      end
    rescue
      flash[:success] = "Unable to open web site"
    end
  end
  
  def showNoBands
    flash[:success] = "No Bands found"
  end

  def siteSupported(url)  
    a = Array.new
    # !!! all array values should be entered as lowercase
    a[0] = /thephoenix/
    a[1] = /testsite/ #made up value

    val = 0

    a.each do |aStr|
      if (aStr =~ url.downcase)
        val = 1
        break
      end
    end

    return (val)
  end

end
