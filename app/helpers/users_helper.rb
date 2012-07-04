module UsersHelper

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
    videoId = User.betweenTwoStrings(youTubeUrl,'v/','\?')
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
    
    trackCode = User.getTrackInfo(result.band)
    if (trackCode != nil)
      tracks << " #{trackCode}"
    end
  end
  return tracks
end