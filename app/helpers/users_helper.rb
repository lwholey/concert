module UsersHelper

  def show_you_tube_video(youTubeUrl, bandName, eventName)
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
      videoId = UsersHelper.between_two_strings(youTubeUrl,'v/','\?')
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

  def get_spotify_tracks(results)
    cache = [] 
    tracks = ""
    results.each do |result|
      bandFound = false
      cache.each do |searchedBand|
        if (result.band == searchedBand)
          bandFound = true
        end
      end
      if (bandFound == true)
        next
      end
      cache << result.band
      trackCode = get_track_info(result.band)
      if (trackCode != nil)
        tracks << " #{trackCode}"
      end
    end
    tracks
  end

  def get_track_info(bandName)
    url = create_artist_url(bandName)
    artist = search_artist(url)
    album = lookup_artist(artist)
    trackCode = lookup_album(album)
  end

  #create the url in Spotify format for the band name 
  def create_artist_url(str1)
    val = nil
    if (str1 != nil)
      #remove leading and trailing whitespace
      str2 = str1.lstrip.rstrip
      str2 = User.remove_accents(str2)
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
    val
  end

  #returns Spotify's coded value for artist
  #TODO : Handle case where more than one artist is returned
  def search_artist(url)
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

  #returns Spotify's coded value for the first
  #album that is available in the US (look for US or worldwide)
  def lookup_artist(artist)
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
        logic1 = UsersHelper.available_in_US(str1)
        if (logic1 == true)
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
  def lookup_album(album)
    if album == nil
      return nil
    end
    url = "http://ws.spotify.com/lookup/1/?uri=spotify:album:" + \
      "#{album}" + "&extras=trackdetail"
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
        logic1 = UsersHelper.available_track(str1)
        popularity = UsersHelper.track_popularity(str1)
        if ((logic1 == true) && (popularity >= maxPopularity))
          maxPopularity = popularity
          trackCode = UsersHelper.between_two_strings(str1,"spotify:track:","\"")
          trackCode = "spotify:track:#{trackCode}"
          tmp = UsersHelper.between_two_strings(str1,"<artist","</artist>")
        end
        k += 1
      end
    rescue
    end
    return trackCode
  end

  #Looks at a string like ...
  #<availability>
  #        <territories>AT AU BE CH CN CZ DK EE ES FI FR GB HK HR HU IE IL IN IT LT LV MY NL NO NZ PL PT RU SE SG SK TH TR TW UA ZA</territories>
  #      </availability>
  #and returns true if US or worldwide otherwise returns nil
  def self.available_in_US(str1)
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
        val = true
        break
      end
    end
    return(val)
  end

  #looks at a string like <popularity>0.131271839142</popularity>
  #and returns the number
  def self.track_popularity(str1)
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
  def self.available_track(str1)
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
      val = true
    end
    return(val)
  end

  # using str1, return what's between str2 and str3
  def self.between_two_strings(str1, str2, str3)
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
  end

end
