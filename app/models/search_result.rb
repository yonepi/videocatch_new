class SearchResult < ApplicationRecord

    require "./app/models/concerns/video_notification"
    include WebPush    
    include UsersHelper
 
    #■APIで得られるデータは殆どjson形式だが、Rubyでjsonを使うためのライブラリは以下を参照（https://qiita.com/yertea/items/be6f535fc31d7325ed97）
    require 'net/http'
    require 'uri'
    require "json" #jsonを使うためのライブラリ

    
    #■youtubeAbiの初期化部分（https://daily.belltail.jp/?p=2330）を参照
    #Google API Ruby Clientの中から、使用する予定のAPIをrequireして呼び出す
    #google-api-client (0.9.28)のVersionが0.9以降の場合、'google/apis/youtube_v3'のように使用するAPIのサービス名も記載する
    require 'google/apis/youtube_v3'
    #presentメソッドを使用するために、'active_support/all'を宣言
    require 'active_support/all'
    
    #■ニコニコ動画のコンテンツ検索APIでは投稿者情報が得られないため「getthumbinfo」を使用するが、こちらで得られるデータはxml形式になるため、xmlを扱えるよう下記を読み込む  
    #http://nekotheshadow.hatenablog.com/entry/2015/01/18/115432
    require "rexml/document"
    
    def self.notice
        WebPush.notification!
    end    

    def self.published_time_check
        today_video = SearchResult.where(published_time: Time.current.ago(1.day)..Time.current)
        today_video.update_all(term: "oneday")
        
        in_1months_video = SearchResult.where(published_time: Time.current.ago(1.months)..Time.current.ago(1.day))
        in_1months_video.update_all(term: "in_1months")
        
        SearchResult.where("published_time < ?", Time.current.ago(1.months)).destroy_all
    end
    
    def self.timecheck(settime)
        if settime < Time.current.ago(1.months)
            @termtime="delete"
        elsif settime < Time.current.ago(1.week)
            @termtime="in_1months"
        elsif settime < Time.current.ago(1.day)
            @termtime="in_1week"
        else
            @termtime="oneday"
        end
    end

    def self.youtube_serch
        serch_all = SearchDatum.all
        nowtime = Time.current
        
        #以下のように記載することで、youtube data Apiのメソッドが使用できるようになる。
        #https://qiita.com/taptappun/items/a217b7017316881d6459
        youtube = Google::Apis::YoutubeV3::YouTubeService.new
        youtube.key = ENV["YOUTUBE_APIKEY"]
        #next_page_tokenの初期値にnilを代入（begin～end while next_page_token.present?でnext_page_tokenが無い場合に処理を終了させるため）
        next_page_token = nil        
        serch_all.each do |serchdata|
            begin
            puts serchdata.keyword 
                #■list_searchesの設定について
                #list_searchesの一つ一つの値の詳細はhttps://developers.google.com/youtube/v3/docs/search/list?hl=jaから)
                results = youtube.list_searches(part="snippet",
                                                q: serchdata.keyword ,#検索クエリと記載されているが、つまり検索キーワードっぽい。
                                                type: 'video',#検索クエリの対象をvideoのみに制限。デフォルトでは video,channel,playlist全てが対象
                                                max_results: 50,#一度に最大で得られる検索結果数。指定できるMaxの値は50。デフォルトは5。
                                                order: :date,#API レスポンス内のリソースの並べ替え。dataの場合、リソースを作成日の新しい順に並べる
                                                page_token: next_page_token,#これが意味わからん、、、が、とにかく、これを記載しておくと検索結果が50以上あっても全部取得できる。
                                                published_after: 1.day.ago.iso8601,#動画投稿日が指定した値より後か先か。
                                                published_before: Time.current.iso8601)#動画投稿日が指定した値より後か先か。
                #Rubyで使用するため、to_hで検索結果のresultsをハッシュ化する。
                results_items = results.to_h
                serch_results = results_items[:items]
                if serch_results.blank?#検索結果が一つもなかった場合、メソッドの処理が停止されるため次のsearchdata.keywordに移動
                  next
                end
                serch_results.each do |serch_result|
                    #以下は動画時間を取得するための部分
                    video_duration_get = youtube.list_videos(part='contentDetails', id: serch_result[:id][:video_id])
                    video_duration_get_h = video_duration_get.to_h
                    duration_item = video_duration_get_h[:items]
                    if duration_item.blank?#list_videosで取得したデータのうち[:items]が空の場合があり、その際にメソッドが止まってしまうため、nextを入れる（動画が削除されている場合かな？）
                        next
                    end
                    time = duration_item[0][:content_details][:duration]
                    time2 = ActiveSupport::Duration.parse(time)
                    #Rubyでメソッド外から変数を参照したい場合の方法。メソッドの返り値を変数に代入する。
                    #http://melborne.github.io/2009/08/26/Ruby/
                    @termtime = SearchResult.timecheck(serch_result[:snippet][:published_at])
                if serch_result[:snippet][:title].match(/#{serchdata.keyword}/i) || serch_result[:snippet][:description].match(/#{serchdata.keyword}/i)
                    if SearchResult.find_by(user_id: serchdata.user_id,keyword: serchdata.keyword,video_url:"https://www.youtube.com/watch?v=#{serch_result[:id][:video_id]}")
                        videoinfo = SearchResult.find_by(user_id: serchdata.user_id,keyword: serchdata.keyword,video_url:"https://www.youtube.com/watch?v=#{serch_result[:id][:video_id]}")
                        videoinfo.update(
                            user_id: serchdata.user_id,
                            keyword: serchdata.keyword,
                            get_time: nowtime.to_s(:db),#to_s(:db)は時刻をDBに保存する際に、Railsで受け取れるために使用するフォーマット
                            thumbnail_url: serch_result[:snippet][:thumbnails][:medium][:url],
                            title: serch_result[:snippet][:title],
                            video_url: "https://www.youtube.com/watch?v=#{serch_result[:id][:video_id]}",
                            channel: serch_result[:snippet][:channel_title],
                            channel_url: "https://www.youtube.com/channel/#{serch_result[:snippet][:channel_id]}",
                            #整数を時刻に変換するTime.atで変換。https://marketing-web.hatenablog.com/entry/second_to_00-00-00
                            duration: Time.at(time2).strftime('%X'),
                            published_time: serch_result[:snippet][:published_at],
                            site:"youtube",
                            term: @termtime
                            )
                        #1か月以上前の動画（@termtime="delete"）は削除
                        if videoinfo.term == "delete"
                            videoinfo.destroy
                        end
                    else
                        SearchResult.create(
                        user_id: serchdata.user_id,
                        keyword: serchdata.keyword,
                        get_time: nowtime.to_s(:db),#to_s(:db)は時刻をDBに保存する際に、Railsで受け取れるために使用するフォーマット
                        thumbnail_url: serch_result[:snippet][:thumbnails][:medium][:url],
                        title: serch_result[:snippet][:title],
                        video_url: "https://www.youtube.com/watch?v=#{serch_result[:id][:video_id]}",
                        channel: serch_result[:snippet][:channel_title],
                        channel_url: "https://www.youtube.com/channel/#{serch_result[:snippet][:channel_id]}",
                        #整数を時刻に変換するTime.atで変換。https://marketing-web.hatenablog.com/entry/second_to_00-00-00
                        duration: Time.at(time2).strftime('%X'),
                        published_time: serch_result[:snippet][:published_at],
                        site:"youtube",
                        term: @termtime
                        )
                    end
                end
            end
            #rescueは何らかの原因でbegin内の処理が実行できなかった場合に、実行をストップせずにrescueとend内の処理を行ってくれる。
            #下記の構文では、エラーが発生した場合にエラーの内容をeに代入している。この場合は"何か問題が発生しました。"の下部にエラー内容を表示する
            rescue Google::Apis::YoutubeV3::YouTubeService => e
              puts "何か問題が発生しました。"
              puts e.result.body
            #検索結果がmax_results:50以上ある場合に、次ページの検索結果を代入
            next_page_token = results.next_page_token
            #next_page_tokenが空ではない場合、begin処理を実行（後判定型のWhile）
            end while next_page_token.present?
        end
        SearchResult.published_time_check
    end
    
    def self.nicovideo_serch
        serch_all = SearchDatum.all
        nowtime = Time.current
        serch_all.each do |serchdata|
            nicoserch = URI.encode("https://api.search.nicovideo.jp/api/v2/video/contents/search?q=#{serchdata.keyword}&targets=title,description,tags&fields=contentId,title,startTime,lengthSeconds,thumbnailUrl&filters[startTime][gte]=#{nowtime.ago(1.day).strftime("%Y-%m-%dT%H:%M:%S")}&filters[startTime][lt]=#{nowtime.strftime("%Y-%m-%dT%H:%M:%S")}&_sort=-viewCounter&_offset=0&_limit=100&_context=video_chath")
            nicojson = Net::HTTP.get(URI.parse(nicoserch))
            #文字列からhash形式に変換する(下記の操作をしないと、Viewで表示する際にincompatible character encodings: UTF-8 and ASCII-8BITエラーが表示される)
            nicohash = JSON.parse(nicojson)
            #ニコ動のJSONデータは、キー名がシンボルではなく文字列になっている。そのため参照する際には[:data]ではなく["data"]で参照しなければいけない。
            nicodatas = nicohash["data"]
            puts nicodatas
            nicodatas.each do |nicodata|
                begin
                    #以下は投稿者データのための部分（ニコ動のコンテンツ検索APIでは投稿者名が取得できないので、投稿者名を取得するために下記を使う。）
                    #http://nekotheshadow.hatenablog.com/entry/2015/01/18/115432
                    uri = URI.parse("http://ext.nicovideo.jp/api/getthumbinfo/#{nicodata["contentId"]}")
                    http = Net::HTTP.get(uri) 
                	#上記で獲得できるデータはxml形式になるので、REXML::Document.new(res)で代入する
                	xml = REXML::Document.new(http)
                	nico_user_id = xml.root.elements["thumb/user_id"].text
                	nico_user_nickname = xml.root.elements["thumb/user_nickname"].text
                    #Rubyでメソッド外から変数を参照したい場合の方法。メソッドの返り値を変数に代入する。
                    #http://melborne.github.io/2009/08/26/Ruby/
                    @termtime = SearchResult.timecheck(Time.parse(nicodata["startTime"]))

                if SearchResult.find_by(user_id: serchdata.user_id,keyword: serchdata.keyword,video_url:"https://www.nicovideo.jp/watch/#{nicodata["contentId"]}")
                videoinfo = SearchResult.find_by(user_id: serchdata.user_id,keyword: serchdata.keyword,video_url:"https://www.nicovideo.jp/watch/#{nicodata["contentId"]}")
                videoinfo.update(
                    user_id: serchdata.user_id,
                    keyword: serchdata.keyword,
                    get_time: nowtime.to_s(:db),#to_s(:db)は時刻をDBに保存する際に、Railsで受け取れるために使用するフォーマット
                    thumbnail_url: nicodata["thumbnailUrl"],
                    title: nicodata["title"],
                    video_url: "https://www.nicovideo.jp/watch/#{nicodata["contentId"]}",
                    channel: nico_user_nickname,
                    channel_url: "https://www.nicovideo.jp/user/#{nico_user_id}",
                    #整数を時刻に変換するTime.atで変換。https://marketing-web.hatenablog.com/entry/second_to_00-00-00
                    duration: Time.at(nicodata["lengthSeconds"]).strftime('%X'),
                    published_time: Time.parse(nicodata["startTime"]),
                    site:"nicovideo",
                    term: @termtime
                    )
                    #1か月以上前の動画（@termtime="delete"）は削除
                    if videoinfo.term == "delete"
                        videoinfo.destroy
                    end
                else
                    SearchResult.create(
                    user_id: serchdata.user_id,
                    keyword: serchdata.keyword,
                    get_time: nowtime.to_s(:db),
                    thumbnail_url: nicodata["thumbnailUrl"],
                    title: nicodata["title"],
                    video_url: "https://www.nicovideo.jp/watch/#{nicodata["contentId"]}",
                    channel: nico_user_nickname,
                    channel_url: "https://www.nicovideo.jp/user/#{nico_user_id}",
                    duration: Time.at(nicodata["lengthSeconds"]).strftime('%X'),
                    published_time: Time.parse(nicodata["startTime"]),
                    site:"nicovideo",
                    term: @termtime
                    )
                end
                rescue
                  next
                end
            end
        end
        SearchResult.published_time_check
    end    

    def self.dailymotionvideo_serch
        serch_all = SearchDatum.all
        nowtime = Time.current
        #dailymotionAPIで検索をかける際、時間の表記はUNIXタイムスタンプ式じゃないといけないため、以下の式で変換する。
        #※なんかいろんなサイトでTime.parse('2009-02-14 08:31:30 +0900').to_iを見るけど、これは、文字列から変換する場合で、そのままタイムクラスを使う場合には直接.to_iで整数にしてあげると良い。
        unix_oneday_ago = nowtime.ago(1.day).to_i
        serch_all.each do |serchdata|
            daily = URI.encode("https://api.dailymotion.com/videos?search=#{(serchdata.keyword)}&fields=title,description,owner.username,owner.url,url,duration,created_time,thumbnail_medium_url&created_after=#{unix_oneday_ago}&limit=100")
            #フィルターの指定は下記リストの中から、created_after=1536632401のように、指定していく。
            #https://developer.dailymotion.com/api#video-filters
            #jsonで取得できるデータは色々あるけど、以下のApiExplorerから「fields」欄で取得したい項目を選択後、searchに検索ワードを入力していくと、絞り込みやすい。	
            #https://developer.dailymotion.com/tools#/video/list
            #"created_time"=>1455894594のように表示されるが、これは、UNIXタイムスタンプで取得しているっぽい。
            #右記のサイトで変換を試してみると、正常に表示される（https://url-c.com/tc/）
            #RubyではTime.at(1455894594)でDate形式で取得できる
            dailyjson = Net::HTTP.get(URI.parse(daily))
            #上記で表示されるJSON値の中に日本語が含まれていると→の様に文字化けした値が表示される。（\u3053\u3076\u3057\u30d5\u30a1\u30af\u30c8\u30ea\u30fc \uff0a \u30b5\u30f3\u30d0\uff01\u3053\u3076\u3057\u30b8\u30e3\u30cd\u30a4\u30ed）
            #これは、JSON-Encodeというコードで置き換えれば正常に表示されるっぽい。
            #http://lab.kiki-verb.com/mojibakeratta/
            #そして、、、Rubyでは、JSON.parseを使用すると自動的に変換される（JSON.parseは文字列形式で取得したJSONを自動でハッシュにしてくれる機能）
            dailyhash = JSON.parse(dailyjson)
            dailyitems = dailyhash["list"]
            
            dailyitems.each do |dailyitem|
                @termtime = SearchResult.timecheck(Time.at(dailyitem["created_time"]))   
                #■DailymotionAPIで日本語で検索すると、関係ない奴らの検索結果も多数表示される、英語だと表示されない。
                #API explore(https://developer.dailymotion.com/tools/apiexplorer#/video/list)で日本語検索試しても駄目。
                #そして、実際のDailymotionでも「こぶしファクトリー」と検索して全然関係ないチャンネルが表示されるので、日本語検索の限界かもしれない。
                #なので、、、取得したハッシュから、タイトルと説明文に「こぶしファクトリー」と記載されているもののみを引っ張る無理矢理処理を行う。
                #値に文字列が含まれるかどうかについては、include?で判断できるので、View側でif文を使用し表示の出しわけを行う。
                #の、予定だったが、includeでは、大文字小文字まで完全一致らしいので、ちょっと修正して、正規表現＋.matchで条件分岐(juice=juiceが上手く検索に引っかからないのよ。)
                #https://blog.codecamp.jp/ruby-regex
                if dailyitem["title"].match(/#{serchdata.keyword}/i) || dailyitem["description"].match(/#{serchdata.keyword}/i)
                    if SearchResult.find_by(user_id: serchdata.user_id,keyword: serchdata.keyword,video_url: dailyitem["url"])
                    videoinfo = SearchResult.find_by(user_id: serchdata.user_id,keyword: serchdata.keyword,video_url: dailyitem["url"])
                    videoinfo.update(
                        user_id: serchdata.user_id,
                        keyword: serchdata.keyword,
                        get_time: nowtime.to_s(:db),#to_s(:db)は時刻をDBに保存する際に、Railsで受け取れるために使用するフォーマット
                        thumbnail_url: dailyitem["thumbnail_medium_url"],
                        title: dailyitem["title"],
                        video_url: dailyitem["url"],
                        channel: dailyitem["owner.username"],
                        channel_url: dailyitem["owner.url"],
                        #整数を数値に変換するTime.atで変換。https://marketing-web.hatenablog.com/entry/second_to_00-00-00
                        duration: Time.at(dailyitem["duration"]).strftime('%X'),
                        published_time: Time.at(dailyitem["created_time"]),#左記で格納されたデータのクラスを調べたところViewで「ActiveSupport::TimeWithZone」となるはずが、何故かNilClassとなっており、どんなデータになっているか調査が必要。ていうか、、、データそのものが無い。。。
                        site:"dailymotion",
                        term: @termtime
                        )
                        #1か月以上前の動画（@termtime="delete"）は削除
                        if videoinfo.term == "delete"
                            videoinfo.destroy
                        end               
                    else
                        SearchResult.create(
                        user_id: serchdata.user_id,
                        keyword: serchdata.keyword,
                        get_time: nowtime.to_s(:db),#to_s(:db)は時刻をDBに保存する際に、Railsで受け取れるために使用するフォーマット
                        thumbnail_url: dailyitem["thumbnail_medium_url"],
                        title: dailyitem["title"],
                        video_url: dailyitem["url"],
                        channel: dailyitem["owner.username"],
                        channel_url: dailyitem["owner.url"],
                        #整数を数値に変換するTime.atで変換。https://marketing-web.hatenablog.com/entry/second_to_00-00-00
                        duration: Time.at(dailyitem["duration"]).strftime('%X'),
                        published_time: Time.at(dailyitem["created_time"]),
                        site:"dailymotion",
                        term: @termtime
                        )
                    end
                end        
            end
        end
        SearchResult.published_time_check
    end 
    
end
