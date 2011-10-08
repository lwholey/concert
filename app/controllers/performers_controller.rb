class PerformersController < ApplicationController

  YOU_TUBE_LENGTH = 11

  def performers
    @performer = Performer.new(params[:performer])
    @title = "performer"
    @user = User.new
    if ( (@performer.performer != nil) && (@performer.you_tube_url != nil) &&
      (@performer.you_tube_url.length == YOU_TUBE_LENGTH) )
      binding.pry
      @performer.performer.downcase!
      @performer.save
      redirect_to :action => 'performers'
    end
  end

end
