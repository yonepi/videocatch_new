# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron


# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

#cron.logを吐き出す場所を指定。以下のように、作成したプロジェクトの位置を含むパスを指定するとよい。
set :output, '/home/ec2-user/environment/video_catch/log/cron.log' 
# 実行環境を指定
set :environment, :development

#whenever動作チェックのためのタスク
#every 1.minutes do 
    #runner "User.hello" , :environment => 'development'
#end

every 1.day, at: ['12:00 pm', '8:00 pm'] do
    rake 'serech_everyday::find_youtubevideo' , :environment => 'development'
    #DBを扱うメソッドを実行するときは、:environment => 'development'で開く（developmentは開発環境。）
    #rake上でも、DBを扱うメソッドを実行するときは、:environment => 'development'で開かないとテーブルが見つからなかったりする。    
end

every 1.day, at: ['12:00 pm', '8:00 pm'] do
    rake 'serech_everyday:find_nicovideo' , :environment => 'development'
end

every 1.day, at: ['12:00 pm', '8:00 pm'] do
    rake 'serech_everyday:find_dailymotionvideo' , :environment => 'development'
end

every 1.day, at: ['12:00 pm', '8:00 pm'] do
    rake 'serech_everyday:notice' , :environment => 'development'
end