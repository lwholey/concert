# The base class for scraping web sites for band names.
#
# This class serves as a factory class for the specific
# scrapers that extend it.  
#
# Call Scraper.create(URL) to create an instance of one of its subclasses.  The
# specific subclass to create is determined based on the URL that is passed in.
# 
# Call scrape(maxBands) on that instance returns a band list array after 
# scraping the URL.
#

class Scraper

  @@urlHash = {}

  def Scraper.setHash
    # The keys in this hash are a regular expression that should
    # match the URL of the website that the function matching
    # that key can scrape.
    @@urlHash = {
      /thephoenix/  => PhoenixScraper,
      /newyorker/  => NewYorkerScraper,
      /cal.startribune.com/  => StarTribuneScraper,
      /events.sfgate.com/  => TribuneScraper,
      /calendar.triblive.com/  => TribuneScraper,
      /calendar.denverpost.com/  => TribuneScraper,
      /getshowtix.com/   => ShowTixScraper,
      /findlocal.latimes.com/  => LaTimesScraper,
    }
  end

  def Scraper.siteSupported?(url)
    if getHashValue(url) == nil
      return false
    else
      return true
    end
  end

  def Scraper.getHashValue(url)
    if @@urlHash.empty?
      setHash
    end

    @@urlHash.each_key do |key| 
      if key =~ url 
        puts "Found #{key} for URL #{url}, returning #{@@urlHash[key]}"
        return @@urlHash[key]
      end
    end
    return nil
  end

  def initialize(url)
    @url = url
  end

  # Return an instance of the subclass that is capable of scraping URL.
  # If no appropriate subclass is found, return nil.
  def Scraper.create(url)
    subClass = getHashValue(url)
    if subClass == nil
      return nil
    else
      return subClass.new(url)
    end
  end

  def to_s
    "Scraper for Site: '#{@url}'"
  end

  # This function wraps the call to the the specialized scraping function
  # 'doScrape'.  It performs the actions that are common to all scraping
  # methods like opening the URL, debugging puts statements and exception
  # handling.
  def scrape( maxBands )
    @maxBands = maxBands
    @bandsArray = Array.new

    puts("Scraping {#@url}")

    begin
      @doc = Nokogiri::HTML(open(@url))
      # Call the scraping function, it populates @bandsArray.  
      doScrape

      if @bandsArray.size > 0

        @bandsArray.each do |band|
          puts("band = #{band}")
        end

        return @bandsArray

      else
        return nil
      end

    rescue
      puts ("Rescue called")
      puts( $! ); # print the exception
      # assumes that the only reason rescue is called is because Nokogiri could not open web site
      return "BadWebSite"
    end
  end
end

#
# The rest of this file are classes that extend Scraper to provide
# the specialized doScrape methods.
#

class PhoenixScraper < Scraper

  # returns an array of strings of band names (returns nil if no bands found)
  def doScrape

    @doc.css(".event-list-title").each do |concert|
      bandNames = concert.text.chomp.gsub(/\r|\n/,"")
      bandNames.split("+").each do |band|
        if (@bandsArray.size >= @maxBands)
          break
        end
        @bandsArray << band.lstrip.rstrip

      end

      if (@bandsArray.size >= @maxBands)
        break
      end

    end

  end

end

class NewYorkerScraper < Scraper

  # returns an array of strings of band names (returns nil if no bands found)
  def doScrape

    m = 0

    @doc.css(".v").each do |concert|

      if (m >= @maxBands)
         break
      end

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

        #only keep bands that have alphanumeric characters
        i = /\w/ =~ str
        if (i != nil)
          @bandsArray[m] = str
          m = m + 1
        end
      
      end

    end
  end

end

class StarTribuneScraper < Scraper
  def doScrape
    str = @doc.to_s

    # find "div id="p_", 
    # then find all ">"
    # then find second "</a"
    str1 = "div id=\"p_"
    str2 = ">"
    str3 = "</a"
    str4 = "startribune footer"

    j = 0
    k = 0
    n = 0
    m = 0
    p = 0
    firstStr3Found = 0
    strState = 0

    for i in (0...str.length)
      case(strState)
      when 0
        if (str[i] == str1[j])
          j += 1
          if (j == str1.length)
            strState = 1
            j = 0
          end
        else
          j = 0
        end
      when 1
        if (str[i] == str2[0])
          k = i
        end

        if (str[i] == str3[n])
          n += 1
          if (n == str3.length)
            if (firstStr3Found == 0)
              firstStr3Found = 1
            else
              @bandsArray[m] = str[k+1..(i-str3.length)]
              puts("@bandsArray[#{m}] = #{@bandsArray[m]}")
              m += 1
              if (m >= @maxBands)
                break
              end
              strState = 0
              firstStr3Found = 0
            end
            n = 0
            k = 0
          end
        else
          n = 0
        end

      else puts("shouldn't ever reach here")
      end

      # stop searching once the footer has been reached
      if (str[i] == str4[p])
        p += 1
        if (p == str4.length)
          p = 0
          puts("footer reached")
          break
        end
      else
        p = 0
      end

    end

  end

end


class TribuneScraper < Scraper
  def doScrape

    m = 0

    @doc.css(".meta_content").each do |featuring|
      if (m >= @maxBands)
        break
      end

      # We are expecting comma-separated band names following the
      # the word "Featuring":
      #
      # For example:
      #   "Featuring: Neil Young, Crazy Horse" 
      str = featuring.text
      tmp = "Featuring:"
      re = /#{tmp}/i # make the pattern case-insensitive
      i = re =~ str

      if (i != nil)
        str = str[(i+tmp.length)..-1]
        str.lstrip!.rstrip!.gsub!(/\r|\n/,"")
        @bandsArray << str
        m += 1
      end
    end
  end
end

class ShowTixScraper < Scraper
  def doScrape

    m = 0

    @doc.css(".show").each do |show|
      if (m >= @maxBands)
        break
      end

      str = show.text
      #puts("str = #{str}")

      # items to remove
      # Empty string (done)
      # time - e.g. 7:30PM (implement by removing numbers and :, keep PM for later) (done)
      # CLOSED FOR PRIVATE EVENT (done)
      # Repeated name - e.g. The Bad Plus, The Bad Plus (done)
      # -CD Release (done)
      # Berklee at the Regattabar - (done)

      i = /\w/ =~ str
      if (i != nil)
        # TODO: fix if band name has a number
        str.gsub!(/\d/,"")
        str.gsub!(/:/,"")
        str.gsub!(/Berklee at the Regattabar -/,"")        
        j = /CLOSED/i =~ str
        if (j != nil)
          next
        end
        str.gsub!(/-CD release/i,"")

        # split bands along "PM" (done)
        str.split(/pm/i).each do |band0|
          if (m >= @maxBands)
            break
          end
          tmp = band0.gsub(/pm/i,"")
          tmp = tmp.lstrip.rstrip
          band1 = Array.new
          band1 << tmp
          if ((@bandsArray & band1).empty? == true )
            #puts("@bandsArray = #{@bandsArray}")
            #puts("tmp = #{tmp}")
            @bandsArray << tmp
            m += 1
          end
        end
      end
    end


  end
end

class LaTimesScraper < Scraper
  def doScrape

    m = 0

    @doc.css(".listing_item").each do |show|
      if (m >= @maxBands)
        break
      end

      str = show.text
      # Parse "Candy Claws, Races, Moses Campbell, Masxs" from a string like
      # 2.
      #
      #         Candy Claws, Races, Moses Campbell, Masxs
      #
      #			 Top Pick

      #puts("str = #{str}")

      i = /[.]/ =~ str
      if (i == nil)
        next
      end
      j = /\w/ =~ str[i+1..-1]
      if (j == nil)
        next
      end
      j += (i+1)
      k = /[(\r|\n)]/ =~ str[j+1..-1]
      if (k == nil)
        next
      end
      k += (j+1)
      str2 = str[j-1..k]

      # items to remove
      # Anything before ":", i.e. "Joni's Jazz: Herbie Hancock, Aimee Mann, Chaka Khan, Kurt Elling" (done)
      # Repeated name - e.g. The Bad Plus, The Bad Plus (done)
      i = /:/ =~ str2
      if (i != nil)
        str2 = str2[i+1..-1]
      end

      tmp = str2.lstrip.rstrip
      band1 = Array.new
      band1 << tmp
      if ((@bandsArray & band1).empty? == true )
        @bandsArray << tmp
        m += 1
      end
    end
  end
end
