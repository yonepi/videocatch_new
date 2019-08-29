require 'active_support/core_ext'
require 'active_support/json'
require 'net/http'

module WebPush
  
  ProductionOneSignalAppId= ENV["ONESIGNAL_PRODUCTION_APPID"]
  ProductionSignalRestAPIKey= ENV["ONESIGNAL_PRODUCTION_APIKEY"]

  def self.notification!
    all_user = User.all
    
    all_user.each do |user|
      @title = "#{Time.current.ago(1.days).in_time_zone('Tokyo').strftime("%m-%d")}～#{Time.current.in_time_zone('Tokyo').strftime("%m-%d")}に投稿された動画です"
      @message = ""
      @youtube_message =""
      @nicovideo_message =""
      @dailymotion_message =""
      serch_all = SearchDatum.where(user_id: user.id)
        serch_all.each do |serchdata|
          message_datas = SearchResult.where(user_id: user.id, keyword: serchdata.keyword,term:"oneday")
            @youtube_message += "「#{serchdata.keyword}」#{message_datas.where(site: "youtube").count}本"
            @nicovideo_message += "「#{serchdata.keyword}」#{message_datas.where(site: "nicovideo").count}本"
            @dailymotion_message += "「#{serchdata.keyword}」#{message_datas.where(site: "dailymotion").count}本"
      @message = "■Youtube\n#{@youtube_message}\n■ニコニコ動画\n#{@nicovideo_message}\n■Dailymotion\n#{@dailymotion_message}" 
      end
    
      params = {
        app_id: ProductionOneSignalAppId,
        rest_api_key: ProductionSignalRestAPIKey,#↓の「en」や「jp」は相手のデバイスの環境を指しており、enの場合は英語環境を、jaの場合は日本語環境を指している。（例として、端末を英語設定にしていたらenのメッセージが届く。）
        headings: {en: "#{@title}", ja: "#{@title}"},
        contents: {en: "#{@message}", ja: "#{@message}"},#←メッセージ内容は、stringしか受け取れないッぽい。数値だと#<Net::HTTPBadRequest 400 Bad Request readbody=true>のエラーが表示されて、通知を行うことができなかった。
        include_player_ids: [user.onesignal_id]#user.idに紐づけられた、onesignal_idを所持しているユーザーに通知を送信するよう指定
      }
      one_signal_web_push(params)
    end
  end

  def self.one_signal_web_push(params)
    raise "AppId or RestAPIKey is required" if params[:app_id].blank? || params[:rest_api_key].blank?
    raise "ContentsIsNone" if params[:contents].blank?
    params[:isChromeWeb] = true
    uri = URI.parse('https://onesignal.com/api/v1/notifications')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.path,
                              'Content-Type' => 'application/json',
                              'Authorization' => "Basic #{params[:rest_api_key]}")
    request.body = params.as_json.to_json
    return http.request(request)
  end
end