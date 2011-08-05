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
        j = 0
        k = 0
        tracksString = "Tracks Found (copy-paste to \"Play Queue\" in Spotify):"
        bandsFoundString = "Bands Found in Spotify:"
        bandsNotFoundString = "Bands Not Found in Spotify: "
        doc.css(".event-list-title").each do |concert|
          bandName = concert.text.chomp.gsub(/\r\n/,"")
          str1 = findSpotifyTrack(bandName)
          if (str1 != nil)
            tracksString += " " + str1
            if (k == 0)
              bandsFoundString += " " + bandName
              k = 1
            else
              bandsFoundString += ", " + bandName
            end
            i = i + 1
          else
            if (j == 0)
              bandsNotFoundString += " " + bandName
              j = 1
            else
              bandsNotFoundString += ", " + bandName
            end
          end
        end
        #puts("#{tracksString}")
        flash[:success] = "#{tracksString}"
        flash[:warning] = "#{bandsFoundString}"
        flash[:error] = "#{bandsNotFoundString}"

        if (i == 0)
          flash[:error] = "No bands found"
        end
      
      else
        flash[:error] = "Web site not supported"
      end
    rescue
      flash[:error] = "Unable to open web site"
    end
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
      #flash[:success] = "Unable to get artist from spotify"
      #puts("could not find artist")    
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
      #flash[:success] = "Unable to get artist from spotify"
      #puts("Unable to get artist from Spotify")   
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
      #flash[:success] = "Unable to get artist from spotify"
      #puts("Unable to get artist from Spotify")   
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
