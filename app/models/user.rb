# == Schema Information
#
# Table name: users
#
#  id         :integer         primary key
#  created_at :timestamp
#  updated_at :timestamp
#  city       :string(255)
#  keywords   :string(255)
#  pageNumber :integer
#  max_pages  :integer
#  start_date :string(255)
#  end_date   :string(255)
#  sort_by    :string(255)
#

require 'digest'
class User < ActiveRecord::Base
  require 'nokogiri'
  require 'open-uri'
  require 'eventful/api'
  
  # ensure results are destroyed along with user
  has_many :results, :dependent => :destroy
  has_many :performers
  
  attr_reader :sort_order, :sort_direction
  
  # Eventful API parameters
  DEFAULT_KEYWORDS = 'concert'
  # number of concerts for eventful to return
  PAGE_SIZE = 10
  EVENTFUL_KEY = 'gr2xkHcHxTF3BQNk'
  # YouTube API parameters
  DEVELOPER_KEY = 'AI39si7SV5n5UyDjSu4HZ92aHlfO-TJ_afBaUyFwSFhIWt46aFBD6KqS7TfGuDZR_a9OUL3A4HtxGMOpAf56WNCAAQz_ptBCbw'
  CALLBACK = 'atom'
  CATEGORIES = 'Music'
  VERSION = '2'
  MORE_KEYWORDS = '%2Clive%2Cband'
  ORDER_BY = 'relevance'
  MAX_RESULTS = '10'
  # Echonest API parameters
  ECHONEST_KEY = 'PZWDKUDNKSN4AV3N1'
  ECHONEST_START = 'http://developer.echonest.com/api/v4/'

  def initialize(attributes = {})
    super
    # Start an API session with a username and password
    @eventful = Eventful::API.new EVENTFUL_KEY
    @dates = 'future'
    @sort_order = 'popularity'
    @sort_direction = 'descending'
  end

  def get_results
    begin
      set_eventful_inputs
      results = call_eventful                      
      self.max_pages = results['page_count']
      self.save
      get_you_tube_videos = create_results_for_user(results)
      if get_you_tube_videos
        self.update_results_with_you_tube_url
      end
    rescue
    end
  end

  def set_eventful_inputs
    if city.blank?
      self.city = "usa" 
    end
    if ((start_date.blank?) || (end_date.blank?))
      self.start_date = "future"
      self.end_date = "future"
    end
    if keywords.blank? then 
      self.keywords = DEFAULT_KEYWORDS
    end
    if pageNumber == nil then
      self.pageNumber = 1
    end
    if (sort_by == 'popularity')
      @sort_order = 'popularity'
      @sort_direction = 'descending'
    else
      @sort_order = 'date'
      @sort_direction = 'ascending'
    end
    dates_for_eventful
  end

  # parse date for use by eventful
  # Exact ranges take the form 'YYYYMMDDHH-YYYYMMDDHH', e.g. '2008042500-2008042723'
  # If problem, just return 'future'
  # input are of the form 'mm/dd/yyyy' 
  def dates_for_eventful
    default = 'future'
    begin
      start_month, start_day, start_year = start_date.split('/')
      total_start_days = total_days(start_year, start_month, start_day)
      end_month, end_day, end_year = end_date.split('/')
      total_end_days = total_days(end_year, end_month, end_day)
      if (total_end_days < total_start_days)
        end_month = start_month
        end_day = start_day
        end_year = start_year
      end
      tmp = date_for_eventful(start_year, start_month, start_day) + "-" +
            date_for_eventful(end_year, end_month, end_day)
      if tmp.length == '2008042500-2008042723'.length
        @dates = tmp
      else
        @dates = default
      end
    rescue
      @dates = default
    end
  end

  def total_days(year, month, day)
    year.to_i * 365 + month.to_i * 30 + day.to_i
  end

  def date_for_eventful(year, month, day)
    year + pad_with_zeros(month,2) + pad_with_zeros(day,2) + '00'
  end

  def pad_with_zeros(str, str_length)
    tmp = str.clone
    while tmp.length < str_length
      tmp = '0' + tmp
    end
    tmp
  end

  def call_eventful
    f = Proc.new do |keywords|
      @eventful.call 'events/search',
        :location => city,
        :keywords => keywords,
        :date => @dates,
        :category => 'music',
        :sort_order => @sort_order,
        :sort_direction => @sort_direction,
        :page_size => PAGE_SIZE,
        :page_number => pageNumber
    end
    begin
      results = f.call(keywords)
      if (results['events'] == nil)
        # no concerts so replace keywords with something intelligent from Echonest
        self.keywords = getEchoNestKeyword(keywords)
        results = f.call(keywords)
      end
      return results
    rescue
      return nil
    end
  end

  #returns true on success, otherwise returns nil
  def create_results_for_user(results)
    begin
      eventTmp = bandsTmp = dateTmp = venueTmp = detailsTmp = nil  
      results['events']['event'].each do |event|
        #event will be a Hash if there is more than one event
        if (event.class == Hash)
          name = event['title']
          date = massage_time(event['start_time'])
          venue = event['venue_name']
          details = event['url']
          result_attr = {
            :name => name,
            :date_string => date,
            :venue => venue,           
            :details_url => details   
          }
          if (event['performers'] == nil)
            self.save_results( result_attr, event['title'])
            next
          elsif (event['performers']['performer'].class == Hash)
            perfArray = [ event['performers']['performer'] ]
          else
            perfArray = event['performers']['performer'] 
          end
          perfArray.each do |performer|
            self.save_results( result_attr, performer['name'])
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
        self.save_results( result_attr, eventTmp)
      end
    rescue
      return nil
    end
    return true
  end

  def save_results( result_attr, band)
    begin
      for i in (0...self.results.length)
        if ( (self.results[i].band == band) &&
             (self.results[i].venue == result_attr[:venue]) )
          self.results[i].date_string += ', ' + result_attr[:date_string]
          return nil
        end
      end
      self.results.build( result_attr.merge( :band => band ) ).save
    rescue
      return nil
    end
  end

  def massage_time(time)
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
      return time
    end
  end

  def update_results_with_you_tube_url
    cache = []
    self.results.each do |result|
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
      searchWithQuotes = 1
      url = setYouTubeUrl(band, searchWithQuotes)
      videoUrl = getVideoUrl(url)
      if videoUrl == nil
        searchWithQuotes = 0
        url = setYouTubeUrl(band, searchWithQuotes)
        videoUrl = getVideoUrl(url) 
        if videoUrl == nil
          # take only the text after 'featuring'
          band = find_text_after(band, 'featuring')
          if (band != nil)
            searchWithQuotes = 1
            url = setYouTubeUrl(band, searchWithQuotes)
            videoUrl = getVideoUrl(url)
          end
        end
      end
      updateResultForYoutube( result, videoUrl)
    end
  end

  def find_text_after(str1, str2)
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

  def updateResultForYoutube( result, videoUrl)
    if (videoUrl.nil?)
      return
    end
    result.update_attributes(:you_tube_url => videoUrl)
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
    begin
      maxTracks = 100
      tmp = 'spotify:track:'
      regx1 = /#{tmp}/
      regx2 = /\W/
      doc = Nokogiri::XML(open(url))
      elements = doc.xpath('//xmlns:track')
      titles = elements.map {|e| e.to_s}
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
          trackCode = User.betweenTwoStrings(str1,"spotify:track:","\"")
          trackCode = "spotify:track:#{trackCode}"
          tmp = User.betweenTwoStrings(str1,"<artist","</artist>")
        end
        k += 1
      end
    rescue
    end
    return trackCode
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

  def User.getTrackInfo(bandName)
    url = createArtistUrl(bandName)
    artist = searchArtist(url)
    album = lookupArtist(artist)
    trackCode = lookupAlbum(album)
  end
  
  # using str1, return what's between str2 and str3
  def User.betweenTwoStrings(str1, str2, str3)
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
          "#{CATEGORIES}&q=#{keywordsM}#{MORE_KEYWORDS}&v=#{VERSION}" <<
          "&key=#{DEVELOPER_KEY}&alt=#{CALLBACK}" <<
          "&orderby=#{ORDER_BY}&max-results=#{MAX_RESULTS}"
    return (url)
  end

  # Convert keywords string for use by YouTube
  def massageKeywords(str1, searchWithQuotes)
    str2 = str1.clone
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
      url = ECHONEST_START + 'artist/terms?api_key=' + ECHONEST_KEY + 
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

end
