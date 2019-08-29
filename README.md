# Video_catch
 
指定したキーワードで各種動画サイトを検索し、毎日新着の動画を拾ってくる仕組みを作成しました。

[videocatch.herokuapp.com](https://videocatch.herokuapp.com/)

***自身で使用する場合の事前準備***

1. railsを利用できるサーバー？または、railsが動作する開発環境で利用
2. youtubedataApiを利用するためのAPIkeyの取得
3. 以下のファイルのENV["YOUTUBE_APIKEY"]を自身で取得したYoutubeDataApiのAPIKEYに変更

- /video_catch/app/models/search_result.rb

youtube.key = ENV["YOUTUBE_APIKEY"]

上記で自動動画検索機として作動し、以下のように、当日分の動画を拾ってきてくれます。

![video](https://i.imgur.com/nrbAKgX.png)

***使い方***

新規登録ページで自身の名前とパスワードを登録→取得動画設定ページで、検索キーワードを入力

上記設定後、検索する日時になった場合、指定したキーワードで毎日動画の検索が自動で行われ、「ホーム」にて新着動画が全て表示します。

動画検索の定時実行は、定時処理を行うGem「whenever」を利用して、毎日12時と20時に検索が行われています。

また、私の場合Herokuでデプロイしていますが、Herokuの場合、定時処理を行うGem「whenever」が正常に起動しないため、代わりにHerokuSchedulerを利用しています。

HerokuSchedulerで以下3つのメソッドを登録すれば、指定した時間で各動画サイトの検索が行われます。

- rake serech_everyday:find_youtubevideo
- rake serech_everyday:find_nicovideo
- rake serech_everyday:find_dailymotionvideo

***通知機能***

拾ってきた動画数を、Webpush通知で教えてくれます。

通知機能を加えたい場合、Onesignalの取得が必要になります。

Onesignalの使い方は色々なサイトで説明されているため省略しますが、OnesignalのAppidが取得できたら、以下ファイルのENV["ONESIGNAL_PRODUCTION_APPID"]を自身で取得したOnesignalのappidに変更してください。

- /video_catch/app/views/layouts/application.html.erb
appId = ENV["ONESIGNAL_PRODUCTION_APPID"]

これで多分通知機能がONになるはずです。

***使用ライブラリ***
- Ruby on Rails

