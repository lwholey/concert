module UsersHelper
  require 'nokogiri'
  require 'open-uri'
  require 'eventful/api'


  @@DEFAULT_KEYWORDS = 'concert'

  def self.DEFAULT_KEYWORDS
    @@DEFAULT_KEYWORDS
  end

  # number of concerts for eventful to return
  @@PAGE_SIZE = 10 

  # YouTube API parameters
  @@DEVELOPER_KEY = 'AI39si7SV5n5UyDjSu4HZ92aHlfO-TJ_afBaUyFwSFhIWt46aFBD6KqS7TfGuDZR_a9OUL3A4HtxGMOpAf56WNCAAQz_ptBCbw'
  @@CALLBACK = 'atom'
  @@CATEGORIES = 'Music'
  @@VERSION = '2'
  @@MORE_KEYWORDS = '%2Clive%2Cband'
  @@ORDER_BY = 'relevance'
  @@MAX_RESULTS = '10'

  @@ECHONEST_KEY = 'PZWDKUDNKSN4AV3N1'
  @@ECHONEST_START = 'http://developer.echonest.com/api/v4/'

  def get_fake_results( num )
    results = {  "events" => { "event" => [] }  }

    num.times do |n|
      event = {
        "performers" => { "performer" => {"creator"=>"legalsmith", "id"=>"P1-001-000153086-2", "linker"=>"chuck", "name"=>"Pierce Pettis", "short_bio"=>"singer songwriter", "url"=>"http://eventful.com/performers/pierce-pettis-/P0-001-000153086-2?utm_source=apis&utm_medium=apim&utm_campaign=apic"}},
        "title" => Faker::Name.name,
        "start_time" => "2012-02-10 20:00:00",
        "venue_name" => "me &amp; thee coffeehouse",
        "url" => "http://eventful.com/marblehead/events/pierce-pettis-connor-garvey-/E0-001-041702648-3?utm_source=apis&utm_medium=apim&utm_campaign=apic"
      }
      puts "event: " + event.to_s
      results["events"]["event"] << event
    end
    return results
  end

  # Parses bands from web sites and creates playlist for Spotify
  def get_results(user)

    begin
      if Rails.env == 'test'
        # if there are more than 30 results we'll paginate
        results = get_fake_results(10)
      else
        puts "Starting EVENTFUL session"

        if user.city.blank? then 
          city = "usa" 
        else
          city = user.city
        end
        if ((user.start_date.blank?) || (user.end_date.blank?)) then 
          start_date = "future"
          end_date = "future"
        else
          start_date = user.start_date
          end_date = user.end_date
        end
        if user.keywords.blank? then 
          keywords = @@DEFAULT_KEYWORDS
        else
          keywords = user.keywords
        end
        if user.pageNumber == nil then
          user.pageNumber = 1
        end

        # Start an API session with a username and password
        eventful = Eventful::API.new 'gr2xkHcHxTF3BQNk'

        date = massageDate(start_date, end_date)

        if (user.sort_by == 'popularity')
          sort_order = 'popularity'
          sort_direction = 'descending'
        else
          sort_order = 'date'
          sort_direction = 'ascending'
        end

        results = call_eventful(eventful, city, keywords, date, sort_order, sort_direction, user.pageNumber)
        #puts("results = #{results}")                       

        if (results['events'] == nil)
          # no concerts so replace keywords with something intelligent from Echonest
          keywords = getEchoNestKeyword(keywords)
          puts("Echonest keywords = #{keywords}")
          results = call_eventful(eventful, city, keywords, date, sort_order, sort_direction, user.pageNumber)
        end
        
        user.max_pages = results['page_count']
        user.save
        
      end

      create_results_for_user( results, user )
      #update_results_with_spotify_tracks( user )
      update_results_with_you_tube_url( user )


    rescue
      flash[:error] = "No concerts found"
      puts $!
    end
  end

  def call_eventful(eventful, city, keywords, date, sort_order, sort_direction, pageNumber)
    if (keywords == nil)
      return nil
    end
    begin
      results = eventful.call 'events/search',
        :location => city,
        :keywords => keywords,
        :date => date,
        :category => 'music',
        :sort_order => sort_order,
        :sort_direction => sort_direction,
        :page_size => @@PAGE_SIZE,
        :page_number => pageNumber
      return results
    rescue
      return nil
    end
  end

  

  def create_results_for_user ( results, user )

    begin
      eventTmp = bandsTmp = dateTmp = venueTmp = detailsTmp = nil  
      results['events']['event'].each do |event|
        #event will be a Hash if there is more than one event
        if (event.class == Hash)
          name = event['title']
          date = massageTime(event['start_time'])
          venue = event['venue_name']
          details = event['url']

          puts "Name: " + name.to_s
          puts "Date " + date.to_s
          puts "Venue " + venue.to_s
          puts "Details " + details.to_s

          result_attr = {
            :name => name,
            :date_string => date,
            :venue => venue,           
            :details_url => details   
          }

          if (event['performers'] == nil)
            user.results.build( result_attr.merge( :band => event['title'] ) ).save
            next
          elsif (event['performers']['performer'].class == Hash)
            perfArray = [ event['performers']['performer'] ]
          else
            perfArray = event['performers']['performer'] 
          end

          perfArray.each do |performer|
            user.results.build( result_attr.merge( :band => performer['name'] ) ).save
          end
        else
          case event[0]
          when 'title'
            eventTmp = event[1]
          when 'start_time'
            dateTmp = event[1]
          when 'venue_name'
            venueTmp = event[1]
          when 'url'
            detailsTmp = event[1]
          else
          end
        end
      end

      if (eventTmp != nil)
        result_attr = {
          :name => eventTmp,
          :date_string => dateTmp,
          :venue => venueTmp,           
          :details_url => detailsTmp   
        }
        user.results.build( result_attr.merge( :band => eventTmp ) ).save
      end
      

    rescue
      puts "Rescue called in create_results_for_user ... "
      puts $1
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
  # Exact ranges take the form 'YYYYMMDDHH-YYYYMMDDHH', e.g. '2008042500-2008042723'
  # If problem, just return 'future'
  # input are of the form 'mm/dd/yyyy' 
  def massageDate(start_date, end_date)
    tmp = 'future'
    if ( (start_date != 'future') && (end_date != 'future') &&
          (start_date.length == 10) &&
          (end_date.length == 10) )
      start_month = start_date[0..1]
      start_day = start_date[3..4]
      start_year = start_date[6..9]

      total_start_days = start_year.to_i * 365 + 
                         start_month.to_i * 30 +
                         start_day.to_i

      end_month = end_date[0..1]
      end_day = end_date[3..4]
      end_year = end_date[6..9]

      total_end_days =   end_year.to_i * 365 + 
                         end_month.to_i * 30 +
                         end_day.to_i

      if (total_end_days < total_start_days)
        end_month = start_month
        end_day = start_day
        end_year = start_year
      end

      #'YYYYMMDDHH-YYYYMMDDHH'
      tmp = start_year + start_month + start_day + "00" + "-" +
            end_year + end_month + end_day + "00"

    end
    return tmp
  end

  class SpotifyResult
    attr_accessor :band, :trackCode, :trackName
    def initialize(attributes = {})
      @band = attributes[:band]
      @trackCode = attributes[:trackCode]
      @trackName = attributes[:trackName]
    end
  end


  # Update the eventful results with spotify track data.
  #
  # If no spotify data is found using the event's band 
  # name we try and split up the band name and if the 
  # new names produce spotify data we will create new
  # results.
  def update_results_with_spotify_tracks( user )

    @cache = []

    user.results.each do |result|
      spotifyData = findSpotifyTrack(result.band ) 
      if ( spotifyData != nil )
        updateResultAndCache( result, spotifyData )
      end
    end

  end

  def update_results_with_you_tube_url( user )
    cache = []
    
    user.results.each do |result|
      band = remove_accents(result.band)
      bandFound = 0
      cache.each do |searchedBand|
        if (band == searchedBand)
          bandFound = 1
        end
      end
      if (bandFound == 1)
        next
      end
      cache << band
      
      videoUrl = findYouTubeVideo(band)
      
      if (videoUrl == nil) 
        searchWithQuotes = 1
        url = setYouTubeUrl(band, searchWithQuotes)
        videoUrl = getVideoUrl(url)
        if videoUrl == nil
          searchWithQuotes = 0
          url = setYouTubeUrl(band, searchWithQuotes)
          videoUrl = getVideoUrl(url) 
          if videoUrl == nil
            # take only the text after 'featuring'
            band = findTextAfter(band, 'featuring')
            if (band != nil)
              searchWithQuotes = 1
              url = setYouTubeUrl(band, searchWithQuotes)
              videoUrl = getVideoUrl(url)
            end
          end
        end
      end
      
      updateResultForYoutube( result, videoUrl)
    end
    
  end

  def findTextAfter(str1, str2)
    str = nil
    regx = /#{str2}/
    i = regx =~ str1
    if (i != nil)
      tmp = i + str2.length
      if tmp < str1.length
        str = str1[tmp...str1.length]
      end
    end
    return str
  end

  # check model for presence of band and YouTube url
  def findYouTubeVideo(band)
    url = nil
    
    @performer = Performer.where("performer = ?", band.downcase)
    puts("band = #{band}")
    #if more than one performer, just use the first
    @performer.each do |tmp|
      url = "https://www.youtube.com/v/"+tmp.you_tube_url+"?version=3"
      puts("url = #{url}")
      break
    end
    return url
    
  end

  def updateResultForYoutube( result, videoUrl)
    if (videoUrl.nil?)
      return
    end
    result.update_attributes(:you_tube_url => videoUrl)
    
  end

  def updateResultAndCache( result, spotifyData )
    if (spotifyData.nil?)
      return
    end

    result.update_attributes(
      :track_spotify => spotifyData.trackCode,
      :track_name => spotifyData.trackName
    )
    @cache << spotifyData
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
    if url == nil
      return nil
    end
    
    if Rails.env.test?
      return "test artist"
    end

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
  def lookupArtist(artist)
    if artist == nil
      return nil
    end
    
    url = "http://ws.spotify.com/lookup/1/?uri=spotify:artist:" + \
      "#{artist}" + "&extras=album"
    
    if Rails.env.test?
      return "test artist"
    end
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
  def lookupAlbum(album)
    if album == nil
      return nil
    end
    
    url = "http://ws.spotify.com/lookup/1/?uri=spotify:album:" + \
      "#{album}" + "&extras=trackdetail"
    
    if Rails.env.test?
      return (["test-track-code", "test-track-name", "test-artist"])
    end

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
          trackCode = "spotify:track:#{trackCode}"
          trackName = betweenTwoStrings(str1,"<name>","</name>")
          tmp = betweenTwoStrings(str1,"<artist","</artist>")
          artistName = betweenTwoStrings(tmp,"<name>","</name>")
          artistName.gsub!("&amp;","and")
        end
        k += 1
      end

    rescue

    end

    puts("trackCode = #{trackCode}")
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

  def findSpotifyTrack( bandName )
    trackCode = nil
    trackName = nil
    artistName = nil

    #don't find a spotify track twice
    @cache.each do |spotifyResult|
      if (spotifyResult.band == bandName)
        return nil
      end
    end

    spotifyResult = SpotifyResult.new
    trackCode, trackName, artistName = getTrackInfo(bandName)

    if (trackCode != nil)
      attr = {:band => bandName, :trackCode => trackCode, :trackName => trackName}
      return SpotifyResult.new( attr )
    else
      return nil
    end
  end

  def getTrackInfo(bandName)
    url = createArtistUrl(bandName)
    artist = searchArtist(url)
    album = lookupArtist(artist)
    trackCode, trackName, artistName = lookupAlbum(album)
    return([trackCode,trackName,artistName])
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

  # url to send to YouTube API requesting info
  def setYouTubeUrl(keywords, searchWithQuotes)
   	keywordsM = massageKeywords(keywords, searchWithQuotes)
   	url = "https://gdata.youtube.com/feeds/api/videos?category=" <<
          "#{@@CATEGORIES}&q=#{keywordsM}#{@@MORE_KEYWORDS}&v=#{@@VERSION}" <<
          "&key=#{@@DEVELOPER_KEY}&alt=#{@@CALLBACK}" <<
   	      "&orderby=#{@@ORDER_BY}&max-results=#{@@MAX_RESULTS}"
   	return (url)
  end

  # Convert keywords string for use by YouTube
  def massageKeywords(str1, searchWithQuotes)
   	str2 = str1
   	if (str2 != nil)
   	  #replace anything that's not an alphanumeric character with white space
   	  str2 = str2.gsub(/\W/," ")
   	  #replace more than one consecutive white spaces with one white space
   	  str2.squeeze!(" ")
   	  #remove leading and trailing whitespace
   	  str2 = str2.lstrip.rstrip
   	  #change to lower case
   	  str2 = str2.downcase
   	  if (searchWithQuotes == 1)
     	  str2.gsub!(" ", "+")
     	  str2 = "%22" + str2 + "%22"
     	else
     	  #replace whitespace with %2C
     	  str2.gsub!(" ", "%2C")
   	  end
   	end  

   	return str2
  end

  # get URL for youTube video, should be able to copy paste
  # str into a browser and see the video
  def getVideoUrl(url)
    begin
     	doc = Nokogiri::XML(open(url))
     	node=doc.xpath('//xmlns:entry')
     	video_count=node.length
     	ids=node.xpath('//media:group/yt:videoid')
     	#just pull the first returned video (should be the most popular of MAX_RESULTS)
     	if (ids != nil)
       	str = "https://www.youtube.com/v/"+ids[0].text+"?version=3"
       	#puts("str = #{str}")
       	return str
     	else
     	  return nil
      end
    rescue
      return nil
    end
  end
  
  def getEchoNestKeyword(band)
    # example call
    # http://developer.echonest.com/api/v4/artist/
    # terms?api_key=N6E4NIOVYMTHNDM8J&name=radiohead&format=json 
    tmp = band.gsub(' ', '+').lstrip.rstrip
    
    begin
      url = @@ECHONEST_START + 'artist/terms?api_key=' + @@ECHONEST_KEY + 
            '&name=' + tmp + '&sort=frequency' '&format=xml'
     	doc = Nokogiri::XML(open(url))
      node = doc.xpath('//response/terms/name')
      # pull the keyword with the highest frequency
      keyword = node[0].text
      return keyword
    rescue
      return nil
    end
    
    
  end
  
  module_function :getTrackInfo
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

def clippy(text, bgcolor='#FFFFFF')
  html = <<-EOF
    <object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000"
            width="110"
            height="14"
            id="clippy" >
    <param name="movie" value="/clippy.swf"/>
    <param name="allowScriptAccess" value="always" />
    <param name="quality" value="high" />
    <param name="scale" value="noscale" />
    <param NAME="FlashVars" value="text=#{text}">
    <param name="bgcolor" value="#{bgcolor}">
    <embed src="/clippy.swf"
           width="110"
           height="14"
           name="clippy"
           quality="high"
           allowScriptAccess="always"
           type="application/x-shockwave-flash"
           pluginspage="http://www.macromedia.com/go/getflashplayer"
           FlashVars="text=#{text}"
           bgcolor="#{bgcolor}"
    />
    </object>
  EOF
  html.html_safe
end

def showYouTubeVideo(youTubeUrl, bandName, eventName)
  if (client_browser_name == "notMobile")
    if (eventName == bandName)
      description = "#{eventName}"
    else
      description = "#{eventName} : #{bandName}"
    end
    html = <<-EOF
    <center>
  
    <div class = "youTube-results span-18 round">
      <p> #{description} </p>
      <p>
    	<object style="height: 195px; width: 320px">
    	<param name="movie" value="#{youTubeUrl}">
    	<param name="allowFullScreen" value="true">
    	<param name="allowScriptAccess" value="always">
    	<embed src="#{youTubeUrl}" type="application/x-shockwave-flash" allowfullscreen="true" allowScriptAccess="always" width="320" height="195"></object>
      </p>
    </div>
    </center>
    EOF
    html.html_safe
  else
    videoId = betweenTwoStrings(youTubeUrl,'v/','\?')
    html = <<-EOF
    <!-- 1. The <div> tag will contain the <iframe> (and video player) -->
    <div id="player"></div>

    <script>
      // 2. This code loads the IFrame Player API code asynchronously.
      var tag = document.createElement('script');
      tag.src = "http://www.youtube.com/player_api";
      var firstScriptTag = document.getElementsByTagName('script')[0];
      firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

      // 3. This function creates an <iframe> (and YouTube player)
      //    after the API code downloads.
      var player;
      function onYouTubePlayerAPIReady() {
        player = new YT.Player("player", {
          height: '195px',
          width: '320px',
          videoId: "#{videoId}"
        });
      }


    </script>    
    EOF
    html.html_safe
  end
end

def getSpotifyTracks(results)
  cache = [] 
  
  tracks = ""
  results.each do |result|
    bandFound = 0
    cache.each do |searchedBand|
      if (result.band == searchedBand)
        bandFound = 1
      end
    end
    if (bandFound == 1)
      next
    end
    cache << result.band
    
    trackCode, trackName, artistName = getTrackInfo(result.band)
    if (trackCode != nil)
      tracks << " #{trackCode}"
    end
  end
  return tracks
end