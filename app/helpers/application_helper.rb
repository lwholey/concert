module ApplicationHelper

=begin
  def logo
    #image_tag("logo.png", :alt => "Sample App", :class => "round")
  end
=end
  
  #Return a title on a per-page basis
  def title
    base_title = "Eventful and Spotify Mashup"
    if @title.nil?
      base_title
    else
      "#{base_title} | #{@title}"
    end
  end
  
end
