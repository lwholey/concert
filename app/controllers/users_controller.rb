class UsersController < ApplicationController
  require 'nokogiri'
  require 'open-uri'
  require 'scraper'
  require 'spotify_playlist'

  # maximum number of bands to find tracks for
  $DEFAULT_MAXBANDS = 15

  def new    
    @user = User.new
    @user.name = params[:u]
    @title = "Enter Web Page"
  end

  def create
    @user = User.new(params[:user])

    # only set $maxBands if input is a digit (\D is a non-digit character)
    i = /\D/ =~ @user.maxNumberOfBands
    if (i == nil) # no non-digit chars were found so use input
      @maxBands = @user.maxNumberOfBands.to_i
    else
      @maxBands = $DEFAULT_MAXBANDS
    end
    
    # If form is blank the regexp returns nil and "".to_i returns 0, but 
    # really want the default.
    # TODO: Use form validation instead?
    if (@maxBands == 0)
      @maxBands = $DEFAULT_MAXBANDS
    end

    parseBands

    if @user.save
      redirect_to "/entry"
    else
      redirect_to "/entry"
    end
  end

  # Parses bands from web sites and creates playlist for Spotify
  def parseBands
    
    url = @user.name

    if Scraper.siteSupported?( url )
      s = Scraper.create(url)
      bandsArray = s.scrape(@maxBands)
    
      if (bandsArray != nil)
        createSpotifyPlaylist(bandsArray)
      else
        flash[:error] = "No bands found"
      end

    else
      flash[:error] = "Web site not supported"
    end
  end

end
