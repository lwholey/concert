class CommentsController < ApplicationController
  
  def comments
    @comment = Comment.new(params[:comment])
    @title = "comments"
    @user = User.new
    if (@comment.body != nil)
      @comment.save
      redirect_to :action => 'comments'
    end
  end
  
end
