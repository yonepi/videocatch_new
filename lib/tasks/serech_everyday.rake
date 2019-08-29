namespace :serech_everyday do
    desc "serech_everydayをputsします"

    task :find_youtubevideo => :environment do
        SearchResult.youtube_serch
    end

    task :find_nicovideo => :environment do
        SearchResult.nicovideo_serch
        #,DBを扱うメソッドを実行するときは、:environment => 'development'で開く（developmentは開発環境。）
        #Gem=wheneverを使用する場合、そちらでも、DBを扱うメソッドを実行するときは、:environment => 'development'で開かないとテーブルが見つからなかったりする。
    end
    
    task :find_dailymotionvideo => :environment do
        SearchResult.dailymotionvideo_serch
    end
    
    task :notice => :environment do
        SearchResult.notice
    end
    
end
