class ApplicationController < ActionController::Base
    #ヘルパーをコントローラーで使えるようにするためinclude
    include HomeHelper
    include UsersHelper

    before_action :current_user
    
    def current_user
        if session[:user_id]
            @current_user = User.find_by(id: session[:user_id])
        elsif cookies.signed[:user_id]
            user = User.find_by(id: cookies.signed[:user_id])
            if user && user.authenticated?(cookies[:remember_token])
                @current_user = user
            end
        end
    end

end
