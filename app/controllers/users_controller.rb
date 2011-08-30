class UsersController < ApplicationController
  require 'nokogiri'
  require 'open-uri'
  require 'scraper'
  require 'eventful/api'

  helper_method :getBandHistory
  helper_method :getSpotifyBandHistory
  helper_method :getTrackHistory
  helper_method :client_browser_name

  # maximum number of bands to find tracks for
  $DEFAULT_MAXBANDS = 15

  def new    
    @user = User.new
    #@user.name = params[:u]
    @title = "Home"
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

#    parseBands
    begin

       # Start an API session with a username and password
       eventful = Eventful::API.new 'gr2xkHcHxTF3BQNk',
                                    :user => 'lwrunner1',
                                    :password => 'eventfulnerd1'

       # Lookup an event by its unique id
       event = eventful.call 'events/get',
                             :id => 'E0-001-001042544-7'

       puts "Event Title: #{event['title']}"

       # Get information about that event's venue
       venue = eventful.call 'venues/get',
                             :id => event['venue_id']

       puts "Venue: #{venue['name']}"

    rescue Eventful::APIError => e
       puts "There was a problem with the API: #{e}"
    end


    if @user.save
      redirect_to "/entry"
    else
      redirect_to "/entry"
    end
  end

  def getBandHistory
    return $bandHistory
  end

  def getSpotifyBandHistory
    return $spotifyBandHistory
  end
  
  def getTrackHistory
    return $trackHistory
  end

=begin
  # Parses bands from web sites and creates playlist for Spotify
  def parseBands
    
    url = @user.name
    
    url = prepareUrl(url)

    if Scraper.siteSupported?( url )
      s = Scraper.create(url)
      bandsArray = s.scrape(@maxBands)
    
      if (bandsArray == "BadWebSite")
        flash[:error] = "Could not open web site"  
      elsif (bandsArray == nil)
        flash[:error] = "No bands found"
      else
        createSpotifyPlaylist(bandsArray)
      end

    else
      flash[:error] = "Web site not supported"
    end
  end

=end

  #remove whitespace from the front and prepend http:// if needed
  def prepareUrl(url)

    tmp = url.lstrip
    str = 'http://'
    i = /#{str}/ =~ tmp
    if (i != 0)
      tmp = str + "#{tmp}"
    end

    puts("url in prepareUrl = #{tmp}")
    return (tmp)
  end

  # Create Spotify playlist to display on web site
  # uses an array of strings (bandsArray) as input
  def createSpotifyPlaylist(bandsArray)

    tracksString = ""
    $bandHistory = Array.new
    $spotifyBandHistory = Array.new
    $trackHistory = Array.new

    bandsArray.each do |band|
      trackCode, trackName, artistName = findSpotifyTrack(band)
      if (trackCode == nil)
        multiSplit(band).each do |band1|
          trackCode, trackName, artistName = findSpotifyTrack(band1)
          tracksString = appendStrings(tracksString, trackCode)
          $bandHistory << band1
          $spotifyBandHistory << artistName
          $trackHistory << trackName
        end     
      else
        tracksString = appendStrings(tracksString, trackCode)
        $bandHistory << band
        $spotifyBandHistory << artistName
        $trackHistory << trackName
      end
    end

    if (tracksString != "")
      flash[:success] = "#{tracksString}"
    end

    if ($bandHistory.empty? == false)
      #set to any value
      flash[:warning] = "a"
    end

  end

  def appendStrings(tracksString, str1)

    if (str1 != nil)
      if (tracksString == "")
        tracksString = str1
      else
        tracksString += " " + str1
      end
    end

    return (tracksString)

  end

  #returns Spotify's coded value for artist
  #TODO : Handle case where more than one artist is returned
  def searchArtist(url)
    val = nil

    begin
      tmp = "spotify:artist:"
      regx1 = /#{tmp}/
      regx2 = /\W/

      doc = Nokogiri::XML(open(url))
      elements = doc.xpath('//xmlns:artist')
      titles = elements.map {|e| e.to_s}
      str1 = titles[0].to_s
      i = regx1 =~ str1
      if (i == nil)
        return(val)
      end

      i = i+tmp.length
      j = regx2 =~ str1[i..-1]
      if (j == nil)
        return(val)
      end
      j = j + i - 1
      val = str1[i..j]

    rescue

    end

    return (val)
  end

  #Looks at a string like ...
  #<availability>
  #        <territories>AT AU BE CH CN CZ DK EE ES FI FR GB HK HR HU IE IL IN IT LT LV MY NL NO NZ PL PT RU SE SG SK TH TR TW UA ZA</territories>
  #      </availability>
  #and returns 1 if US or worldwide otherwise returns nil
  def availableInUS(str1)
    val = nil

    tmp = '<territories>'
    regx1 = /#{tmp}/
    regx2 = /</

    a = Array.new
    a[0] = /US/
    a[1] = /worldwide/

    i = regx1 =~ str1
    if (i == nil)
      return(val)
    end

    i = i+tmp.length
    j = regx2 =~ str1[i..-1]
    j = j + i - 1
    str2 = str1[i..j]

    a.each do |aStr|
      if (aStr =~ str2)
        val = 1
        break
      end
    end

    return(val)
  end

  #looks at a string like <popularity>0.131271839142</popularity>
  #and returns the number
  def trackPopularity(str1)
    val = nil

    tmp = '<popularity>'
    regx1 = /#{tmp}/
    regx2 = /</

    i = regx1 =~ str1
    if (i == nil)
      return(val)
    end

    i = i+tmp.length
    j = regx2 =~ str1[i..-1]
    if (j == nil)
      return(val)
    end
    j = j + i - 1
    val = str1[i..j].to_f

    return(val)

  end

  #looks at a string like <available>true</available>
  #and returns true if true (nil otherwise)
  def availableTrack(str1)
    val = nil

    tmp = '<available>'
    regx1 = /#{tmp}/
    regx2 = /</
    a = /true/

    i = regx1 =~ str1
    if (i == nil)
      return(val)
    end

    i = i+tmp.length
    j = regx2 =~ str1[i..-1]
    if (j == nil)
      return(val)
    end
    j = j + i - 1
    str2 = str1[i..j]

    if (a =~ str2)
      val = 1
    end

    return(val)
  end

  #returns Spotify's coded value for the first
  #album that is available in the US (look for US or worldwide)
  def lookupArtist(url)
    val = nil

    begin
      maxAlbums = 100
      tmp = 'spotify:album:'
      regx1 = /#{tmp}/
      regx2 = /\W/

      doc = Nokogiri::XML(open(url))
      elements = doc.xpath('//xmlns:album')
      titles = elements.map {|e| e.to_s}

      k=0
      titles.each do |str1|
        i = regx1 =~ str1
        if ((i == nil) || (k >= maxAlbums))
          break
        end
        i = i+tmp.length
        j = regx2 =~ str1[i..-1]
        if (j == nil)
          return(val)
        end
        j = j + i - 1
        logic1 = availableInUS(str1)
        if (logic1 == 1)
          val = str1[i..j]
          break
        end
        k = k + 1
      end

    rescue

    end

    return(val)
  end

  #returns Spotify's coded value for the first
  #track that is available
  #assume min track popularity is 0
  def lookupAlbum(url)
    trackCode = nil
    trackName = nil
    artistName = nil

    begin
      maxTracks = 100
      tmp = 'spotify:track:'
      regx1 = /#{tmp}/
      regx2 = /\W/

      doc = Nokogiri::XML(open(url))
      elements = doc.xpath('//xmlns:track')
      titles = elements.map {|e| e.to_s}
      #puts(titles)
      k=0
      maxPopularity = 0.0
      titles.each do |str1|
        if (k >= maxTracks)
          break
        end
      
        logic1 = availableTrack(str1)
        popularity = trackPopularity(str1)
        if ((logic1 == 1) && (popularity >= maxPopularity))
          maxPopularity = popularity
          trackCode = betweenTwoStrings(str1,"spotify:track:","\"")
          trackName = betweenTwoStrings(str1,"<name>","</name>")
          tmp = betweenTwoStrings(str1,"<artist","</artist>")
          artistName = betweenTwoStrings(tmp,"<name>","</name>")
        end
        k += 1
      end

    rescue

    end

    return([trackCode,trackName,artistName])
  end

  def remove_accents(str)

    # Modified code from
    # RemoveAccents version 1.0.3 (c) 2008-2009 Solutions Informatiques Techniconseils inc.
    # http://www.techniconseils.ca/en/scripts-remove-accents-ruby.php
    # The extended characters map used by removeaccents. The accented characters 
    # are coded here using their numerical equivalent to sidestep encoding issues.
    # These correspond to ISO-8859-1 encoding.
    tmp = str
    accents_mapping = {
      'E' => [200,201,202,203],
      'e' => [232,233,234,235],
      'A' => [192,193,194,195,196,197],
      'a' => [224,225,226,227,228,229,230],
      'C' => [199],
      'c' => [231],
      'O' => [210,211,212,213,214,216],
      'o' => [242,243,244,245,246,248],
      'I' => [204,205,206,207],
      'i' => [236,237,238,239],
      'U' => [217,218,219,220],
      'u' => [249,250,251,252],
      'N' => [209],
      'n' => [241],
      'Y' => [221],
      'y' => [253,255],
      'AE' => [306],
      'ae' => [346],
      'OE' => [188],
      'oe' => [189]
    }

      accents_mapping.each {|letter,accents|
      packed = accents.pack('U*')
      rxp = Regexp.new("[#{packed}]")
      tmp.gsub!(rxp, letter)
    }
    return(tmp)
  end

  #create the url in Spotify format for the band name 
  def createArtistUrl(str1)
    val = nil
    if (str1 != nil)
      #remove leading and trailing whitespace
      str2 = str1.lstrip.rstrip
      str2 = remove_accents(str2)
      #remove quintet, quartet, trio (makes it easier for Spotify to search)
      str2.gsub!(/quintet/i,"")
      str2.gsub!(/quartet/i,"")
      str2.gsub!(/trio/i,"")
      #remove tribute (may want to include actual bands who are playing the tribute as well)
      str2.gsub!(/tribute/i,"")
      #keep only whitespace, alphanumeric characters, comma, ampersand, and period
      i = /[^(\w|\s|,|&|.)]/ =~ str2
      if (i != nil)
        str2 = str2[0...i]
      end
      str2 = str2.lstrip.rstrip
      str2.gsub!(" ", "%20")
      str2.gsub!("&", "%26")
      val = "http://ws.spotify.com/search/1/artist?q=" + str2
    end

    return(val)
  end

  def findSpotifyTrack(bandName)
    trackCode = nil
    trackName = nil
    artistName = nil
  
    url = createArtistUrl(bandName)
  
    if (url != nil)
      artist = searchArtist(url)

      if (artist != nil)
        url = "http://ws.spotify.com/lookup/1/?uri=spotify:artist:" + \
              "#{artist}" + "&extras=album"
        album = lookupArtist(url)

        if (album != nil)
          url = "http://ws.spotify.com/lookup/1/?uri=spotify:album:" + \
                "#{album}" + "&extras=trackdetail"
          trackCode, trackName, artistName = lookupAlbum(url)
          if (trackCode != nil)
            if (artistName != nil)
              artistName.gsub!("&amp;","and")
            end
            trackCode = "spotify:track:#{trackCode}"
            puts("trackCode = #{trackCode}")
          end
        end
      end
    end

    return ([trackCode,trackName,artistName])
  end

  #split a string into an array
  # E.g. "the bad plus, kurt rosenwinkel, and the rolling stones" ->
  # ["the bad plus", "kurt rosenwinkel", "the rolling stones"]
  def multiSplit(str)
    val = str
  
    splitArray = Array.new
    splitArray[0] = ' and '
    splitArray[1] = ','
    splitArray[2] = "&amp;"
    splitArray[3] = '&'
  
    splitArray.each do |tmp|
      tmp2 = val.split("#{tmp}")
      val = tmp2.join("-")
    end
    val.gsub!("--","-")
    val = val.split("-")

    return (val)
  
  end

  # using str1, return what's between str2 and str3
  def betweenTwoStrings(str1, str2, str3)
    val = nil
  
    i = /#{str2}/ =~ str1
    if (i == nil)
      return val
    end
    tmp = i+str2.length
    j = /#{str3}/ =~ str1[(tmp)..-1]
    if (j == nil)
      return val
    end
    val = str1[(tmp)...(tmp+j)]
    return val
  end
  
end

def client_browser_name 
  user_agent = request.env['HTTP_USER_AGENT'].downcase 
  if user_agent =~ /mobile/i 
    "mobile" 
  elsif user_agent =~ /android/i
    "mobile"
  else
    "notMobile" 
  end 
end
