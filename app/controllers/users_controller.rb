class UsersController < ApplicationController

  def sign_in
    @user = User.new()
  end
  
  def new
    @user = User.new(name: params[:name], password: params[:password])
    @user.save
    if @user.save == true
      flash[:notice] = "新規登録しました。"
      session[:user_id] = @user.id
      #永続ログイン機能の処理
      remember(@user)
      redirect_to("/#{@user.id}/top")
    else 
      @error_messages = @user.errors.full_messages
      render("users/sign_in")
    end
  end
  
  def loginform
    @user = User.new()
  end
  
  def login
    @user = User.find_by(name: params[:name])
    if @user && @user.authenticate(params[:password])
      flash[:notice] = "ログインしました。"
      session[:user_id] = @user.id
      if params[:remember_me] == "1"
        #永続ログイン機能の処理
        remember(@user)
      end
      redirect_to("/#{@user.id}/top")
      #redirect_to("/users/onesignal_set")
    else 
      #ここで、@userにUser.new(name: params[:name], password: params[:password])を代入することで、loginformをrender後に@userの値を使用することが出来る
      #つまり、要はユーザーが入力した内容が再表示される
      @user = User.new(name: params[:name], password: params[:password])
      flash[:notice] = "メールアドレス、またはパスワードが違います"
      render("users/loginform")
    end
  end
  
  def logout
      @current_user.forget
      cookies.delete(:user_id)
      cookies.delete(:remember_token)
      @user=nil
      session[:user_id]=nil
      flash[:notice] = "ログアウトしました。"
      redirect_to("/users/login")
  end
  
  #OnesignalのUserIdを受け取るためのアクションコントローラー
  #jqueryのAjax通信でパラメータを受け取っている。
  def onesignal_set
    onesignal = params[:onesignal_id]
    if User.find_by(onesignal_id: "#{onesignal}")
      onesignal_id_deleteuser = User.find_by(onesignal_id: "#{onesignal}")
      onesignal_id_deleteuser.update(onesignal_id: nil)
    end
    @current_user.update(onesignal_id: "#{onesignal}")
    redirect_to("/#{@current_user.id}/top")
  end

end