Rails.application.routes.draw do
  root 'users#loginform'

  get "home/about" => "home#about"
  get ":id/top" => "home#top"
  
  get "users/login" => "users#loginform"
  post "users/login" => "users#login"
  get 'users/sign_in' => "users#sign_in"
  post "users/sign_in" =>"users#new"
  post "users/logout" => "users#logout"   
  #ログイン時にonesignalidを受け取る用
  get "users/onesignal_set" => "users#onesignal_set"
  #既にログイン中のユーザーがホームボタンをクリックした際にonesignalidを受け取る用
  get ":id/users/onesignal_set" => "users#onesignal_set"

  post "serch_data/serch_config" => "serch_data#create"
  get ":id/serch_config" => "serch_data#serch_config"
  post ":id/serch_destroy" => "serch_data#destroy"
  
  
  
  
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

end
