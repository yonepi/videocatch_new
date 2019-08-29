module UsersHelper
    
  # ユーザーのセッションを永続的にする
  def remember(user)
    user.remember#ここのrememberはUserクラスで設定したremember（userにはコントローラー上でUserオブジェクトの値が代入されるため）
    cookies.permanent.signed[:user_id] = user.id
    cookies.permanent[:remember_token] = user.remember_token
  end
  
  # 永続的セッションを破棄する
  def forget(user)
    user.forget
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end

  # 現在のユーザーをログアウトする
  def log_out
    forget(current_user)
    session.delete(:user_id)
    @current_user = nil
  end
  
end
