require_relative 'boot'
require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module VideoCatch
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    #lib以下のファイルの読み込みのためにはautoloadの設定が必要なため、以下を追加
    #https://qiita.com/okamu_/items/541ac96a1380b26d95c8
    config.autoload_paths += %W(#{config.root}/lib)
    # 特にここ！！Rails5から productionでも呼び出せるように設定しないといけない
    config.enable_dependency_loading = true 
    
    #active_jobにdelayed_jobを設定（「Delayed Job使うよ」とActive Jobに伝えるための設定）
    config.active_job.queue_adapter = :delayed_job
    
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    
  end
end