class HomeController < ApplicationController

  require "./app/models/concerns/video_notification"
  include WebPush

  def about
    @testtime = Time.zone.name
    puts Time.zone.name
    if @current_user
      @cookie_id = @current_user.remember_digest
    end
    @session_id = session[:user_id]
  end
  
  
  def top
      @user = User.find_by(id: params[:id])
      @serch_all = SearchDatum.where(user_id: session[:user_id])
      @youtube_all =SearchResult.where(user_id: session[:user_id],site:"youtube").order("published_time DESC")
      @nicovideo_all = SearchResult.where(user_id: session[:user_id],site:"nicovideo").order("published_time DESC")
      @dailyvideo_all =SearchResult.where(user_id: session[:user_id],site:"dailymotion").order("published_time DESC")
      
      if @current_user == nil
        flash[:notice] = "ログイン後に可能な操作です"
        redirect_to("/users/login")
      else
        if  @user.id == @current_user.id
        else
          flash[:notice] = "不正なアクセスです"
          redirect_to("/users/login")
        end 
      end
  end

end
