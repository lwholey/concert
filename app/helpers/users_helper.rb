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
  @@MORE_KEYWORDS = '%2Cband'
  @@ORDER_BY = 'relevance'
  @@MAX_RESULTS = '10'


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
        results = get_fake_results(40)
      else
        puts "Starting EVENTFUL session"

        if user.city.blank? then 
          city = "usa" 
        else
          city = user.city
        end
        if user.dates.blank? then 
          dates = "future" 
        else
          dates = user.dates  
        end
        if user.keywords.blank? then 
          keywords = @@DEFAULT_KEYWORDS
        else
          keywords = user.keywords
        end

        # Start an API session with a username and password
        eventful = Eventful::API.new 'gr2xkHcHxTF3BQNk'

        date = massageDate(dates)

        if (user.keywords == @@DEFAULT_KEYWORDS )
          sort_order = 'popularity'
          sort_direction = 'descending'
        else
          sort_order = 'relevance'
          #puts("sort_order = #{sort_order}")
          sort_direction = 'descending'
        end

        results = eventful.call 'events/search',
          :location => city,
          :keywords => keywords,
          :date => date,
          :category => 'music',
          :sort_order => sort_order,
          :sort_direction => sort_direction,
          :page_size => @@PAGE_SIZE

        #puts("results = #{results}")                       

        if (results['events'] == nil)
          # flash no concerts found and exit
          flash[:error] = "No concerts found"
          return
        end
      end

      create_results_for_user( results, user )
      update_results_with_spotify_tracks( user )
      update_results_with_you_tube_url( user )


    rescue
      #   flash[:error] = "No concerts found"
      puts $!
    end
  end

  def create_results_for_user ( results, user )

    begin

      results['events']['event'].each do |event|
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
      end

    rescue
      puts "Rescue called in create_results_for_user ... "
      puts $1
    end

  end

  # put validations like this in model?
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
      if ( spotifyData.nil? )
        multiSplit(result.band).each do |band1|
          spotifyData = findSpotifyTrack( result.band ) 
          if ( !spotifyData.nil? )
            newResult = result.dup();
            newResult.id = nil
            newResult.save
            updateResultAndCache( newResult, spotifyData )
          end
        end     
      else
        updateResultAndCache( result, spotifyData )
      end
    end

  end

  def update_results_with_you_tube_url( user )
    user.results.each do |result|
      searchWithQuotes = 1
      url = setYouTubeUrl(result.band, searchWithQuotes)
      videoUrl = getVideoUrl(url)
      if videoUrl == nil
        searchWithQuotes = 0
        url = setYouTubeUrl(result.band, searchWithQuotes)
        videoUrl = getVideoUrl(url) 
      end
      updateResultForYoutube( result, videoUrl)
    end
    
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
      :track_name => spotifyData.trackName,
      :band => spotifyData.band
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
  def lookupArtist(url)
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
  def lookupAlbum(url)
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

  def findSpotifyTrack( bandName )
    trackCode = nil
    trackName = nil
    artistName = nil

    #don't find a spotify track twice
    @cache.each do |spotifyResult|
      if (spotifyResult.band == bandName)
        return spotifyResult
      end
    end

    spotifyResult = SpotifyResult.new

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
            attr = {:band => artistName, :trackCode => trackCode, :trackName => trackName}

            return SpotifyResult.new( attr )
          end
        end
      end
    end
    return nil
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

def showYouTubeVideo(text)
  html = <<-EOF
  <div class = "youTube-results span-18 round">
  	<object style="height: 195px; width: 320px">
  	<param name="movie" value="#{text}">
  	<param name="allowFullScreen" value="true">
  	<param name="allowScriptAccess" value="always">
  	<embed src="#{text}" type="application/x-shockwave-flash" allowfullscreen="true" allowScriptAccess="always" width="320" height="195"></object>
  </div>
  EOF
  html.html_safe
end

