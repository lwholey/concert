class UsersController < ApplicationController
  require 'nokogiri'
  require 'open-uri'
  require 'eventful/api'

  helper_method :getBandHistory
  helper_method :getSpotifyBandHistory
  helper_method :getTrackHistory
  helper_method :client_browser_name
  helper_method :getEventHistory
  helper_method :getDateHistory
  helper_method :getVenueHistory
  helper_method :getDetailsHistory
  helper_method :getPageNumber
  helper_method :isLastPage
  helper_method :getLastCity
  helper_method :getLastDates
  helper_method :getLastKeywords

  # number of concerts for eventful to return
  $PAGE_SIZE = 5
  $DEFAULT_KEYWORDS = 'concert'

  def new    
    @user = User.new
    @title = "Home"
  end

  def create
    @user = User.new(params[:user])
    
    puts("@user.city = #{@user.city}")
    puts("@user.pageNumber = #{@user.pageNumber}")
    puts("@user.dates = #{@user.dates}")
    puts("@user.keywords = #{@user.keywords}")
    
    keepUserData
    
    if @user.save
      
      if (@user.city.length == 0)
         @user.city = "usa"
      end

      if (@user.dates.length == 0)
         @user.dates = "future"
      end

      if (@user.keywords.length == 0)
        @user.keywords = $DEFAULT_KEYWORDS
      end
      
      parseBands
      redirect_to "/results"
    else
      @title = "Home"
      render 'new'
    end

  end

  def results
    @user = User.new
    @title = "Results"
      #redirect_to "/entry"
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

  def getEventHistory
    return $eventHistory
  end
  
  def getDateHistory
    return $dateHistory
  end
  
  def getVenueHistory
    return $venueHistory
  end
  
  def getDetailsHistory
    return $detailsHistory
  end

  def getPageNumber
    return $pageNumber
  end

  def isLastPage	
    if ($pageNumber >= $totalPages)	
      return true	
    else	
      return false	
    end	
  end

  def getLastCity
    return $city	
  end

  def getLastDates
   	return $dates
  end
  
  def getLastKeywords
    return $keywords	
  end
  
  def keepUserData
    $pageNumber = @user.pageNumber	 	
   	$city = @user.city
   	$dates = @user.dates
   	$keywords = @user.keywords

    if (@user.pageNumber == nil)
      $pageNumber = 1	
    else
      $pageNumber += 1
    end	 	
  end

  # Parses bands from web sites and creates playlist for Spotify
  def parseBands

    # initialize	
    $totalPages = 1

    bandsArray = Array.new
    eventArray = Array.new
    dateArray = Array.new
    venueArray = Array.new
    detailsArray = Array.new

    begin

       # Start an API session with a username and password
       eventful = Eventful::API.new 'gr2xkHcHxTF3BQNk',
                                    :user => 'lwrunner1',
                                    :password => 'eventfulnerd1'

       date = massageDate(@user.dates)
       #puts("date = #{date}")

       if (@user.keywords == $DEFAULT_KEYWORDS )
         sort_order = 'popularity'
         sort_direction = 'descending'
       else
         sort_order = 'relevance'
         puts("sort_order = #{sort_order}")
         sort_direction = 'descending'
       end

       results = eventful.call 'events/search',
                             :location => @user.city,
                             :keywords => @user.keywords,
                             :date => date,
                             :category => 'music',
                             :sort_order => sort_order,
                             :sort_direction => sort_direction,
                             :page_size => $PAGE_SIZE,
                             :page_number => $pageNumber
                             
       $totalPages = results['page_count']
       if (results['events'] != nil)
         eventTmp = bandsTmp = dateTmp = venueTmp = detailsTmp = nil                   
         results['events']['event'].each do |event|
           # if eventful returns more than oven event it will be in hash format
           # if it returns one event, it will be in array format
           if (event.class == Hash)
             if (event['performers'] != nil)
               event['performers']['performer'].each do |performer|
                 if (performer[0] == 'name')
                   if (stripEvent(event['title']))
                     bandsArray << performer[1]
                     eventArray << event['title']
                     dateArray << massageTime(event['start_time'])
                     #dateArray << event['start_time']
                     venueArray << event['venue_name']
                     detailsArray << event['url']
                   end
                 end
               end
             else
               if (stripEvent(event['title']))
                 bandsArray << event['title']
                 eventArray << event['title']
                 dateArray << massageTime(event['start_time'])
                 #dateArray << event['start_time']
                 venueArray << event['venue_name']
                 detailsArray << event['url']
               end
             end
           else
             case event[0]
             when 'title'
               bandsTmp = event[1]
               eventTmp = event[1]
             when 'start_time'
               dateTmp = event[1]
             when 'venue_name'
               venueTmp = event[1]
             when 'url'
               #puts("event[1] = #{event[1]}")
               detailsTmp = event[1]
             else
             end
           end
         end
         
         if ( (eventTmp != nil) && (stripEvent(eventTmp)) )
           bandsArray << bandsTmp
           eventArray << eventTmp
           dateArray << dateTmp
           venueArray << venueTmp
           detailsArray << detailsTmp
         end
         
       end

    rescue
       flash[:error] = "No concerts found"
    end
    
    if (bandsArray.length == 0)
      flash[:error] = "No concerts found"
    else
      createSpotifyPlaylist(bandsArray, eventArray, dateArray, venueArray, detailsArray)
    end

  end

  def stripEvent(event)
    # open mike concerts generally aren't good
    i = /open mike/i =~ event
    if (i != nil)
      puts("found open mike")
      return false
    else
      return true
    end
    
  end

  def massageTime(time)
    
    if (time.class == String)
      timeTmp = DateTime.strptime("#{time}", "%Y-%m-%d %H:%M:%S").to_time
    else
      timeTmp = time
    end
    
    begin  
      t = timeTmp.asctime
      i = /\s/ =~ t
      dayOfWeek = t[0...i]
      month = timeTmp.mon
      day = timeTmp.day
      date = month.to_s + "/" + day.to_s
    
      hour = timeTmp.hour
      minutes = timeTmp.min
      if minutes < 10
        minutes = "0" + minutes.to_s
      end
    
      if (hour > 12)
        hour -= 12
        dateAndTime = "#{dayOfWeek} " + "#{date} " + "#{hour}" + ":" + "#{minutes} " + "PM"
      else
        dateAndTime = "#{dayOfWeek} " + "#{date} " + "#{hour}" + ":" + "#{minutes} " + "AM"
      end
    
      return dateAndTime  
    rescue
      puts ("Rescue called")
      puts( $! ); # print the exception
      return time
    end
    
  end

  # parse date for use by eventful
  # From http://api.eventful.com/libs/ruby/doc/index.html
  # Limit this list of results to a date range, specified by label or exact range. 
  # Currently supported labels include: "All", "Future", "Past", "Today", 
  #{ }"Last Week", "This Week", "Next week", and months by name, e.g. "October". 
  # Exact ranges take the form 'YYYYMMDDHH-YYYYMMDDHH', e.g. '2008042500-2008042723'. (optional)

  # date values that appear to work:
  # all, future, past, today, last week, this week, next week, september, october, november, aug, oct, nov, aug.

  # date values that appear NOT to work:
  # All (the only value that I found to be case sensitive), exact dates?
  
  def massageDate(date)
    tmp = date[0..2].downcase
    
    case tmp
    when 'jan'
      'january'
    when 'feb'
      'february'
    when 'mar'
      'march'
    when 'apr'
      'april'
    when 'may'
      'may'
    when 'jun'
      'june'
    when 'jul'
      'july'
    when 'jun'
      'june'
    when 'aug'
      'august'
    when 'sep'
      'september'
    when 'oct'
      'october'
    when 'nov'
      'november'
    when 'dec'
      'december'
    when 'fut'
      'future'
    when 'pas'
      'past'
    when 'las'
      'last week'
    when 'thi'
      'this week'
    when 'nex'
      'next week'
    when 'all'
      'all'
    when 'tod'
      'today'
    else
      'future'
    end
      
  end

  # Create Spotify playlist to display on web site
  # uses an array of strings (bandsArray) as input
  def createSpotifyPlaylist(bandsArray, eventArray, dateArray, venueArray, detailsArray)

    tracksString = ""
    $bandHistory = Array.new
    $spotifyBandHistory = Array.new
    $trackHistory = Array.new
    $eventHistory = Array.new
    $dateHistory = Array.new
    $venueHistory = Array.new
    $detailsHistory = Array.new
    i = 0

    bandsArray.each do |band|
      trackCode, trackName, artistName = findSpotifyTrack(band, $bandHistory,
                                         $spotifyBandHistory, $trackHistory)
      if (trackCode == nil)
        multiSplit(band).each do |band1|
          trackCode, trackName, artistName = findSpotifyTrack(band1, $bandHistory,
                                             $spotifyBandHistory, $trackHistory)
          tracksString = appendStrings(tracksString, trackCode)
          $bandHistory << band1
          $spotifyBandHistory << artistName
          $trackHistory << trackName
          $eventHistory << eventArray[i]
          $dateHistory << dateArray[i]
          $venueHistory << venueArray[i]
          $detailsHistory << detailsArray[i]
        end     
      else
        tracksString = appendStrings(tracksString, trackCode)
        $bandHistory << band
        $spotifyBandHistory << artistName
        $trackHistory << trackName
        $eventHistory << eventArray[i]
        $dateHistory << dateArray[i]
        $venueHistory << venueArray[i]
        $detailsHistory << detailsArray[i]
      end
      i += 1
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

  def findSpotifyTrack(bandName, bandHistory, spotifyBandHistory, trackHistory)
    trackCode = nil
    trackName = nil
    artistName = nil

    #don't find a spotify track twice
    i = 0
    matchFound = false
    bandHistory.each do |band|
      if (bandHistory[i] == bandName)
        matchFound = true
        break
      end
      i += 1
    end
    
    if (matchFound == false)
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
    else
      artistName = spotifyBandHistory[i]
      trackName = trackHistory[i]
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
