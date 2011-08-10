class UsersController < ApplicationController
  require 'nokogiri'
  require 'mechanize'
  require 'open-uri'

  # maximum number of bands to find tracks for
  $maxBands = 20

  $webSitesHash = Hash.new
  $webSitesHash['thePhoenix'] = 0
  $webSitesHash['newyorker'] = 1 
  $webSitesSupported = Array.new
  # TODO : Fix so that criteria below are not needed
  # !!! all array values should be entered as lowercase
  # !!! Order must match 0, 1, ... order above
  # !!! Sequential values must be used
  $webSitesSupported[0] = /thephoenix/
  $webSitesSupported[1] = /newyorker/
    
  def new
    @user = User.new
    @title = "Enter Web Page"
  end

  def create
    @user = User.new(params[:user])

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
    webSiteIndex = isSiteSupported(url)
    if (webSiteIndex != nil)

      # Scrape band names from webSitesSupported
      case (webSiteIndex)
        when $webSitesHash['thePhoenix']
          bandsArray = scrapeThePhoenix(url)
        when $webSitesHash['newyorker']
          bandsArray = scrapeTheNewYorker(url)
        else 
          bandsArray = nil
      end

      if (bandsArray != nil)
        createSpotifyPlaylist(bandsArray)
      else
        flash[:error] = "No bands found"
      end

    else
      flash[:error] = "Web site not supported"
    end
  end

# returns index of webSitesSupported found,
# otherwise returns nil
  def isSiteSupported(url)  

    val = nil
    i = 0
    $webSitesSupported.each do |aStr|
      #puts("aStr = #{aStr}")
      #puts("url.downcase = #{url.downcase}")
      if (aStr =~ url.downcase)
        val = i
        break
      end
      i += 1
    end

    return (val)
  end

  # returns an array of strings of band names (returns nil if no bands found)
  def scrapeThePhoenix(url)

    begin
      doc = Nokogiri::HTML(open(url))
      bandsArray = Array.new

      m = 0
      tracksString = "Tracks Found (copy-paste to \"Play Queue\" in Spotify):"
      bandsFoundString = "Bands Found in Spotify:"
      bandsNotFoundString = "Bands Not Found in Spotify: "
   
      doc.css(".event-list-title").each do |concert|
        bandNames = concert.text.chomp.gsub(/\r|\n/,"")
        bandNames.split("+").each do |band|
          bandsArray[m] = band.lstrip.rstrip
          puts("bandsArray[m] = #{bandsArray[m]}")
          m = m + 1
          
          if (m > $maxBands)
            break
          end
          
        end
      
        if (m > $maxBands)
          break
        end
      
      end
    
      if (m == 0)
        return(nil)
      else
        return(bandsArray)
      end
    rescue
      return(nil)
    end
    
  end
 
  # returns an array of strings of band names (returns nil if no bands found)
  def scrapeTheNewYorker(url)
    puts("scrapeTheNewYorker")
    begin
      doc = Nokogiri::HTML(open(url))
      bandsArray = Array.new

      m = 0
      tracksString = "Tracks Found (copy-paste to \"Play Queue\" in Spotify):"
      bandsFoundString = "Bands Found in Spotify:"
      bandsNotFoundString = "Bands Not Found in Spotify: "

      doc.css(".v").each do |concert|

        #puts("concert = #{concert}")
        str = concert.to_s
        tmp = "</a"
        tmpRegx = /#{tmp}/
        i = tmpRegx =~ str
        n = nil

        for j in (0...str.length)

          if ('>' == str[j].chr)
            n = j
            #puts("n = #{n}")
          end

          if j == i
            break
          end
        end

        if ( (i != nil) && (n != nil) )
          str = str[n+1...i].lstrip.rstrip
          # E.g. 1 from "this, that, and other" split into 
          # "this", "that", "other"
          # E.g. 2 from "this and that" split into
          # "this", "that"
          str.split("and").each do |band1|
            band1.split(",").each do |band2|
              #only keep bands that have alphanumeric characters
              i = /\w/ =~ band2
              if (i != nil)
                bandsArray[m] = band2.lstrip.rstrip
                puts("bandsArray[m] = #{bandsArray[m]}")
                m = m + 1
              end
            end
          end        
          
        end
        
        if (m > $maxBands)
          break
        end
        
      end

      if (m == 0)
        return(nil)
      else
        return(bandsArray)
      end
    rescue
      puts("rescue called")
      return(nil)
    end

  end

  # Create Spotify playlist to display on web site
  # uses an array of strings (bandsArray) as input
  def createSpotifyPlaylist(bandsArray)

    j = 0
    k = 0

    tracksString = "Tracks Found (copy-paste to \"Play Queue\" in Spotify):"
    bandsFoundString = "Bands Found in Spotify:"
    bandsNotFoundString = "Bands Not Found in Spotify: "

    bandsArray.each do |band|
      str1 = findSpotifyTrack(band)
      puts("Spotify track = #{str1}")
      if (str1 != nil)
        tracksString += " " + str1
        if (k == 0)
          bandsFoundString += " " + band
          k = 1
        else
          bandsFoundString += ", " + band
        end
      else
        if (j == 0)
          bandsNotFoundString += " " + band
          j = 1
        else
          bandsNotFoundString += ", " + band
        end
      end
    end

    flash[:success] = "#{tracksString}"
    flash[:warning] = "#{bandsFoundString}"
    flash[:error] = "#{bandsNotFoundString}"
    flash[:message] = "Number of bands searched exceeded 
                      #{$maxBands} - consider focusing search."
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
        #puts("album found = #{str1[i..j]}")
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
    val = nil

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
        i = regx1 =~ str1
        if ((i == nil) || (k >= maxTracks))
          break
        end
        i = i+tmp.length
        j = regx2 =~ str1[i..-1]
        if (j == nil)
          break
        end
        j = j + i - 1
        logic1 = availableTrack(str1)
        popularity = trackPopularity(str1)
        if ((logic1 == 1) && (popularity >= maxPopularity))
          val = str1[i..j]
          maxPopularity = popularity
        end
        k = k + 1
      end

    rescue
  
    end

    return(val)
  end

  #create the url in Spotify format for the band name 
  def createArtistUrl(str1)
    val = nil

    if (str1 != nil)
      #remove leading and trailing whitespace
      str2 = str1.lstrip.rstrip
      #remove quartet, trio (makes it easier for Spotify to search)
      str2.gsub!(/quartet/,"")
      str2.gsub!(/Quartet/,"")
      str2.gsub!(/QUARTET/,"")
      str2.gsub!(/trio/,"")
      str2.gsub!(/Trio/,"")
      str2.gsub!(/TRIO/,"")
      #keep only whitespace and alphanumeric characters
      i = /[^(\w|\s)]/ =~ str2
      if (i != nil)
        str2 = str2[0...i]
      end
      str2 = str2.lstrip.rstrip
      str2.gsub!(" ", "%20")
      val = "http://ws.spotify.com/search/1/artist?q=" + str2
      #puts("spotify url = #{val}")
    end

    return(val)
  end

  def findSpotifyTrack(bandName)
    val = nil
    
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
          track = lookupAlbum(url)
          if (track != nil)
            val = "spotify:track:#{track}"
            #puts(val)
          end
        end
      end
    end
    
    return (val)
  end

end
