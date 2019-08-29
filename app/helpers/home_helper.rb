module HomeHelper

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
    
    #■ここから実際にYoutubeApiを使うためのメソッド
    def find_videos(keyword)#after: 3.day.ago,には、取得したい期間を入力
      #以下のように記載することで、youtube data Apiのメソッドが使用できるようになる。
      #https://qiita.com/taptappun/items/a217b7017316881d6459
      youtube = Google::Apis::YoutubeV3::YouTubeService.new
      youtube.key = ENV["YOUTUBE_APIKEY"]
      
      #next_page_tokenの初期値にnilを代入（begin～end while next_page_token.present?でnext_page_tokenが無い場合に処理を終了させるため）
      next_page_token = nil
      
      begin
        #■list_searchesの設定について
        #list_searchesの一つ一つの値の詳細はhttps://developers.google.com/youtube/v3/docs/search/list?hl=jaから)
        results = youtube.list_searches(part="snippet",
                                        q: keyword , #検索クエリと記載されているが、つまり検索キーワードっぽい。
                                        type: 'video',#検索クエリの対象をvideoのみに制限。デフォルトでは video,channel,playlist全てが対象
                                        max_results: 50,#一度に最大で得られる検索結果数。指定できるMaxの値は50。デフォルトは5。
                                        order: :date,#API レスポンス内のリソースの並べ替え。dataの場合、リソースを作成日の新しい順に並べる
                                        page_token: next_page_token,#これが意味わからん、、、が、とにかく、これを記載しておくと検索結果が50以上あっても全部取得できる。
                                        published_after: 1.day.ago.iso8601,#動画投稿日が指定した値より後か先か。
                                        published_before: Time.current.iso8601)#動画投稿日が指定した値より後か先か。
        puts "resultsの結果は下記です。"
        puts results
        puts "resultsのクラスは下記です。"
        puts results.class
        
        #Rubyで使用するため、to_hで検索結果のresultsをハッシュ化する。
        results_items = results.to_h
        puts "results_itemsの結果は下記です。"
        puts results_items
        @serch_results = results_items[:items]
        puts "@serch_resultsの結果は下記です。"
        puts @serch_results
        puts "@serch_resultsのクラスは下記です。"
        puts @serch_results.class
        if @serch_results.blank?#検索結果が一つもなかった場合に処理を抜ける
          return 
        end
        
        #Youtube Apiの[:items]は、配列の形式で格納されている。（@serch_results.class）で確認したら、Arrayって表示されるよ。
        #でも、配列の●番目の要素って感じで指定したら、その奥のネストはハッシュになっているので、シンボルで取得できるよ。
        firstvideo_result = @serch_results[0][:id][:video_id]
        puts "テスト結果は下記です"
        puts firstvideo_result
        #list_videos()の最初の因数には、partに指定する部分が入る
        #list_searchesと同様partに値を指定するが動画時間を取得したい場合は、snippetではなく、'contentDetails'を指定。
        testlong = youtube.list_videos(part='contentDetails', id: firstvideo_result)
        #Rubyで使用するため、to_hで検索結果のresultsをハッシュ化する。
        testlong_h = testlong.to_h
        puts "testlong_hの結果は下記です"
        testlong_h = testlong.to_h
        puts testlong_h
        puts "testlong_h_itemの[:duration]は下記です。"
        puts testlong_h[:items][0][:content_details][:duration]
        time = testlong_h[:items][0][:content_details][:duration]
        
        #[:content_details][:duration]で取得できる値はISO8601文字列というフォーマットで取得できる。
        #ActiveSupport::Durationメソッドで、それを数値に直せる。https://techracho.bpsinc.jp/hachi8833/2017_02_07/34824
        time2 = ActiveSupport::Duration.parse(time)
        #これをstrftimeで時間形式の表示に変換する。
        puts Time.at(time2).strftime('%X')
        
        @big_array = []
        key = []
        keynum = 0
        @serch_results.each do |result|
          testman = youtube.list_videos(part='contentDetails', id: result[:id][:video_id])
          testman_h = testman.to_h
          testman_h_items = testman_h[:items]
          testman_dure = testman_h_items.first
          testman_time = testman_dure[:content_details][:duration]
          testman_time2 = ActiveSupport::Duration.parse(testman_time)
          @big_array.push(testman_time2)
          
          key.push(keynum)
          keynum += 1
        end
        ary = key.zip(@big_array)
        @h = Hash[ary]
        
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

    #■ここからニコニコ動画のAPIを使うためのメソッド    
    def find_nicovideos(serch_keyword)
      #Rubyで日本語を含むURLを読み込むと、「URI must be ascii only」のエラーが表示されるため、URI.encodeメソッドを利用してASCII 文字列に対応する形にする。
      #https://loumo.jp/wp/archive/20180628110033/
      nowtime = Time.current
      uri = URI.encode("https://api.search.nicovideo.jp/api/v2/video/contents/search?q=#{serch_keyword}&targets=title,description,tags&fields=contentId,title,startTime,lengthSeconds,thumbnailUrl&filters[startTime][gte]=#{nowtime.ago(1.week).strftime("%Y-%m-%dT%H:%M:%S")}&filters[startTime][lt]=#{nowtime.strftime("%Y-%m-%dT%H:%M:%S")}&_sort=-viewCounter&_offset=0&_limit=100&_context=video_chath")
      puts "uriの結果は下記です。"
      puts uri

      #■コンテンツ検索APIで時刻を利用する場合、「2014-01-01T00:00:00」←この形になっていないといけないっぽい。
      #公式のサンプルでは、「2014-01-01T00:00:00+09:00」のように+09:00が付いているが、これが付いていると、Invalid format: \"09:00" is malformed at \"09:00\"と表示されて、上手く取得できない。
      #https://site.nicovideo.jp/search-api-docs/search.html
      #そのため、strftime("%Y-%m-%dT%H:%M:%S")と記載し、+09:00が付いていない文字列みたいな感じで設定する。（%dと%Hの間の「T」がミソ。%をつけなかったらそのまま文字列として表示されるよ)
      
      nicojson = Net::HTTP.get(URI.parse(uri))
      #文字列からhash形式に変換。キー名がシンボルではなく文字列になっているため、symbolize_names: trueを指定してシンボルに修正
      nicohash = JSON.parse(nicojson , symbolize_names: true)
      puts "nicohashの結果は下記です。"
      puts nicohash
      @nicodates = nicohash[:data]
      puts "@nicodatesの結果は下記です。"
      puts @nicodates
      #以下は投稿者データのための部分（ニコ動のコンテンツ検索APIでは投稿者名が取得できないので、投稿者名を取得するために下記を使う。）
      #http://nekotheshadow.hatenablog.com/entry/2015/01/18/115432
      url = URI.parse("http://ext.nicovideo.jp/api/getthumbinfo/sm35481396")
      http = Net::HTTP.get(url) 
      puts "httpの結果は下記です。"
      puts http
    	#上記で獲得できるデータはxml形式になるので、REXML::Document.new(res)で読み込む
    	xml = REXML::Document.new(http)
      puts "xmlの結果は下記です。"
      puts xml
    	nico_user_id = xml.root.elements["thumb/user_id"].text
    	nico_user_nickname = xml.root.elements["thumb/user_nickname"].text
      puts "nico_user_idの結果は下記です。"
      puts nico_user_id
      puts "nico_user_nicknameの結果は下記です。"
      puts nico_user_nickname
    end 

    #■ここからDailymotionのAPIを使うためのメソッド    
    def find_dailymotionvideo(serch_keyword)
      nowtime = Time.current
      #dailymotionAPIで検索をかける際、時間の表記はUNIXタイムスタンプ式じゃないといけないため、以下の式で変換する。
      #※なんかいろんなサイトでTime.parse('2009-02-14 08:31:30 +0900').to_iを見るけど、これは、文字列から変換する場合で、そのままタイムクラスを使う場合には直接.to_iで整数にしてあげると良い。
      unix_onemonth_ago = nowtime.ago(1.months).to_i
      daily = URI.encode("https://api.dailymotion.com/videos?search=#{serch_keyword}&fields=title,description,owner.username,owner.url,url,duration,created_time,thumbnail_medium_url&created_after=#{unix_onemonth_ago}&limit=100")
      #フィルターの指定は下記リストの中から、created_after=1536632401のように、指定していく。
      #https://developer.dailymotion.com/api#video-filters
      #jsonで取得できるデータは色々あるけど、以下のApiExplorerから「fields」欄で取得したい項目を選択後、searchに検索ワードを入力していくと、絞り込みやすい。	
      #https://developer.dailymotion.com/tools#/video/list
      #"created_time"=>1455894594のように表示されるが、これは、UNIXタイムスタンプで取得しているっぽい。
      #右記のサイトで変換を試してみると、正常に表示される（https://url-c.com/tc/）
      #RubyではTime.at(1455894594)でDate形式で取得できる
      dailyjson = Net::HTTP.get(URI.parse(daily))
      puts "dailyjsonの結果は下記です。"
      puts dailyjson 
      #上記で表示されるJSON値の中に日本語が含まれていると→の様に文字化けした値が表示される。（\u3053\u3076\u3057\u30d5\u30a1\u30af\u30c8\u30ea\u30fc \uff0a \u30b5\u30f3\u30d0\uff01\u3053\u3076\u3057\u30b8\u30e3\u30cd\u30a4\u30ed）
      #これは、JSON-Encodeというコードで置き換えれば正常に表示されるっぽい。
      #http://lab.kiki-verb.com/mojibakeratta/
      #そして、、、Rubyでは、JSON.parseを使用すると自動的に変換される（JSON.parseは文字列形式で取得したJSONを自動でハッシュにしてくれる機能）
      dailyhash = JSON.parse(dailyjson)
      dailyitems = dailyhash["list"]
      puts "dailyitemsの結果は下記です。"
      puts dailyitems
      #■DailymotionAPIで日本語で検索すると、関係ない奴らの検索結果も多数表示される、英語だと表示されない。
      #API explore(https://developer.dailymotion.com/tools/apiexplorer#/video/list)で日本語検索試しても駄目。
      #そして、実際のDailymotionでも「こぶしファクトリー」と検索して全然関係ないチャンネルが表示されるので、日本語検索の限界かもしれない。
      #なので、、、取得したハッシュから、タイトルと説明文に「こぶしファクトリー」と記載されているもののみを引っ張る無理矢理処理を行う。
      #値に文字列が含まれるかどうかについては、include?で判断できるので、View側でif文を使用し表示の出しわけを行う。
      #の、予定だったが、includeでは、大文字小文字まで完全一致らしいので、ちょっと修正して、正規表現＋.matchで条件分岐(juice=juiceが上手く検索に引っかからないのよ。)
      #https://blog.codecamp.jp/ruby-regex
      dailyitems.each do |dailyitem|
        if dailyitem["title"].match(/#{serch_keyword}/i) || dailyitem["description"].match(/#{serch_keyword}/i)
          puts "#{serch_keyword}で抽出した結果です"
          puts dailyitem["title"]
          puts dailyitem["description"]
        end
      end
    end 
    
end
