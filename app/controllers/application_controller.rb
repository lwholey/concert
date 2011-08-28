class ApplicationController < ActionController::Base
  require 'reload_controllers'
  
  protect_from_forgery
  
  before_filter :_reload_controllers, :if => :_reload_controllers?

  def _reload_controllers
    RELOAD_CONTROLLERS.each do |controller|
      require_dependency controller
    end
  end

  def _reload_controllers?
    defined? RELOAD_CONTROLLERS
  end
end
