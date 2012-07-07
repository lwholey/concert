module UsersHelper

  def self.get_spotify_tracks(results)
    cache = [] 
    tracks = ""
    results.each do |result|
      bandFound = false
      cache.each do |searchedBand|
        if result.band == searchedBand
          bandFound = true
        end
      end
      if bandFound == true
        next
      end
      cache << result.band
      trackCode = UsersHelper.get_track_info(result.band)
      unless trackCode
        tracks << " #{trackCode}"
      end
    end
    tracks
  end

  def self.get_track_info(bandName)
    url = UsersHelper.create_artist_url(bandName)
    artist = UsersHelper.get_artist(url)
    album = UsersHelper.get_album(artist)
    trackCode = UsersHelper.get_track_code(album)
  end

  #create the url in Spotify format for the band name 
  def self.create_artist_url(str)
    val = nil
    if str
      val = str.clone
      #remove leading and trailing whitespace
      val.strip!
      val = User.remove_accents(val)
      #keep only whitespace, alphanumeric characters, comma, ampersand, and period
      i = /[^(\w|\s|,|&|.)]/ =~ val
      if (i != nil)
        val = val[0...i]
      end
      #strip again
      val.strip!
      val.gsub!(" ", "%20")
      val.gsub!("&", "%26")
      val = "http://ws.spotify.com/search/1/artist?q=" + val
    end
    val
  end

  #returns Spotify's coded value for artist
  #TODO : Handle case where more than one artist is returned
  def self.get_artist(url)
    if url == nil
      return nil
    end
    val = nil
    begin
      doc = Nokogiri::XML(open(url))
      val = doc.xpath('//xmlns:artist')[0].attributes['href'].value
    rescue
    end
    val
  end

  #returns Spotify's coded value for the first
  #album that is available in the US (look for US or worldwide)
  def self.get_album(artist)
    if artist == nil
      return nil
    end
    url = "http://ws.spotify.com/lookup/1/?uri=" + \
      "#{artist}" + "&extras=album"
    maxAlbums = 100
    val = nil
    begin
      doc = Nokogiri::XML(open(url))
      elements = doc.xpath('//xmlns:album')
      elements.each_with_index do |e , i|
        if UsersHelper.available_in_US?(e)
          val = e.attributes['href'].value
          break
        elsif i > maxAlbums
          break
        end
      end
    rescue
    end
    val
  end

  #returns Spotify's coded value for the most popular, 
  #available track on the album
  def self.get_track_code(album)
    if album == nil
      return nil
    end
    url = "http://ws.spotify.com/lookup/1/?uri=" + \
      "#{album}" + "&extras=trackdetail"
    maxTracks = 100
    maxPopularity = 0.0
    val = nil
    begin
      doc = Nokogiri::XML(open(url))
      elements = doc.xpath('//xmlns:track')
      elements.each_with_index do |e , i|
        if UsersHelper.track_available?(e)
          popularity = elements[0].children[15].children.to_s.to_f
          if popularity > maxPopularity
            maxPopularity = popularity
            val = e.attributes['href'].value
          end
        elsif i > maxTracks
          break
        end
      end
    rescue
    end
    val
  end

  # looks for US or true (case insensitive)
  def self.available_in_US?(elements)
    val = nil
    begin
      elements.children.each do |e|
        if e.name.include?('availability')
          if e.children.children.to_s.include?('US')
            val = true
            break
          end
        end
      end
    rescue
    end
    val
  end

  def self.track_available?(elements)
    val = nil
    begin
      elements.children.each do |e|
        if e.name.include?('available')
          if e.children.to_s.include?('true')
            val = true
            break
          end
        end
      end
    rescue
    end
    val    
  end

  def self.show_you_tube_video(youTubeUrl, bandName, eventName)
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
