module ApplicationHelper
  
  #Return a title on a per-page basis
  def title
    base_title = "lennylonglegs"
    if @title.nil?
      base_title
    else
      "#{base_title} | #{@title}"
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
  
end
