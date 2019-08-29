class User < ApplicationRecord
    #実際にはremember_tokenカラムがDBにないため、attr_accessorで「仮想的」にアクセスできる属性を指定。(テーブルのカラム=オブジェクトの属性)をクラスの中で定義しているイメージ。
    #https://qiita.com/Hassan/items/0e034a1d42b2335936e6
    attr_accessor :remember_token
    
    validates :name, presence: true
    validates :name, uniqueness: true
    
    has_secure_password
    validates :password, presence: true, allow_nil: true
    
    require "./app/models/concerns/video_notification"
    include WebPush
    
    def self.hello
        puts "HelloWorld"
        user = User.first
        puts user.id
        puts Time.zone.name
        puts Time.current
    end
    
    #cookiesの利用についてはRailsチュートリアルを参照。
    #https://railstutorial.jp/chapters/advanced_login?version=5.1#sec-remember_me

    # 渡された文字列のハッシュ値を返す
    def User.digest(string)
        #ここで言うハッシュ化については、「ハッシュ関数を使って、入力されたデータを元に戻せない (不可逆な) データにする」という処理を指している
        #https://railstutorial.jp/chapters/modeling_users?version=5.0#sec-adding_a_secure_password
        #ハッシュ関数は、すごく簡単に言えば、「入力した値に対して、まったく別の値が出力されるという暗号方式」のこと。
        #https://techacademy.jp/magazine/16498
        #今回は、BCryptの暗号方式でハッシュ化している  
        cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                      BCrypt::Engine.cost
        BCrypt::Password.create(string, cost: cost)
    end
    
    # ランダムなトークンを返す
    def User.new_token
        SecureRandom.urlsafe_base64
    end
    
    # 永続セッションのためにユーザーをデータベースに記憶する(rememberメソッド内で)
    def remember
        #self.remember_tokenとすることで、ローカル変数のremember_tokenではなく「attr_accessor :remember_token」により設定された、
        #Userクラス内の属性のremember_token（要は動的にUserのDBにremember_tokenカラムを設定している的な）
        self.remember_token = User.new_token
        #その後、update_attributeメソッドにより、remember_digestの値を更新する。
        update_attribute(:remember_digest, User.digest(remember_token))
    end

    # 渡されたトークンがダイジェストと一致したらtrueを返す
    def authenticated?(remember_token)#ここで設定しているremember_tokenはローカル変数のremember_tokenなので、rememberメソッド内のremember_tokenとは異なる
        BCrypt::Password.new(remember_digest).is_password?(remember_token)
    end
    
    # ユーザーのログイン情報を破棄する
    def forget
        update_attribute(:remember_digest, nil)
    end
    
end