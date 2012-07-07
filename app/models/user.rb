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
        self.keywords = get_echo_nest_keyword(keywords)
        results = f.call(keywords)
      end
      return results
    rescue
      return nil
    end
  end

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
      if eventTmp
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
    true
  end

  def save_results( result_attr, band)
    begin
      # handle case where band might be playing more than one show
      self.results.each do |r|
        if ( (r.band == band) &&
             (r.venue == result_attr[:venue]) )
          r.date_string += ', ' + result_attr[:date_string]
          return
        end
      end
      self.results.build( result_attr.merge( :band => band ) ).save
    rescue
      nil
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
      band = User.remove_accents(result.band)
      bandFound = false
      cache.each do |searchedBand|
        if band == searchedBand
          bandFound = true
        end
      end
      if bandFound == true
        next
      end
      cache << band
      searchWithQuotes = true
      url = set_you_tube_url(band, searchWithQuotes)
      videoUrl = get_video_url(url)
      if videoUrl == nil
        searchWithQuotes = false
        url = set_you_tube_url(band, searchWithQuotes)
        videoUrl = get_video_url(url) 
        if videoUrl == nil
          # take only the text after 'featuring'
          band = find_text_after(band, 'featuring')
          if (band != nil)
            searchWithQuotes = true
            url = set_you_tube_url(band, searchWithQuotes)
            videoUrl = get_video_url(url)
          end
        end
      end
      if videoUrl
        result.update_attributes(:you_tube_url => videoUrl)
      end
    end
  end

  def find_text_after(str1, str2)
    str = nil
    regx = /#{str2}/
    i = regx =~ str1
    if (i != nil)
      tmp = i + str2.length
      if tmp < str1.length
        str = str1[tmp...str1.length].strip
      end
    end
    return str
  end

  # url to send to YouTube API requesting info
  def set_you_tube_url(keywords, searchWithQuotes)
    keywordsM = massage_keywords(keywords, searchWithQuotes)
    url = "https://gdata.youtube.com/feeds/api/videos?category=" <<
          "#{CATEGORIES}&q=#{keywordsM}#{MORE_KEYWORDS}&v=#{VERSION}" <<
          "&key=#{DEVELOPER_KEY}&alt=#{CALLBACK}" <<
          "&orderby=#{ORDER_BY}&max-results=#{MAX_RESULTS}"
  end

  # Convert keywords string for use by YouTube
  def massage_keywords(str1, searchWithQuotes)
    str2 = str1.clone
    if (str2 != nil)
      #replace anything that's not an alphanumeric character with white space
      str2 = str2.gsub(/\W/," ")
      #replace more than one consecutive white spaces with one white space
      str2.squeeze!(" ")
      #remove whitespace
      str2 = str2.strip
      #change to lower case
      str2 = str2.downcase
      if (searchWithQuotes)
        str2.gsub!(" ", "+")
        str2 = "%22" + str2 + "%22"
      else
        #replace whitespace with %2C
        str2.gsub!(" ", "%2C")
      end
   end
   str2
  end

  # get URL for youTube video, should be able to copy paste
  # str into a browser and see the video
  def get_video_url(url)
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
  
  def get_echo_nest_keyword(band)
    # example call
    # http://developer.echonest.com/api/v4/artist/
    # terms?api_key=N6E4NIOVYMTHNDM8J&name=radiohead&format=json 
    tmp = band.gsub(' ', '+').strip
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

  def User.remove_accents(str)
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
    tmp
  end

end
