class User < ActiveRecord::Base
  # 複数所有するmicropostsを関連付け
  #has_many :microposts
  has_many :microposts, dependent: :destroy
  # バリデーション後、保存前の処理
  # -->事前に小文字に変換
  #before_save { self.email = email.downcase }
  before_save { email.downcase! }
  # before_save後、Insertのときのみ呼ばれる
  before_create :create_remember_token

  validates :name,  presence:true, length: { maximum: 50 }

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
  validates :email, presence:true, format: { with: VALID_EMAIL_REGEX },
  				uniqueness: { case_sensitive: false }

  has_secure_password     # Rails 3.1からのパスワード機構
  validates :password, length: { minimum: 6 }

  def User.new_remember_token
    SecureRandom.urlsafe_base64
  end

  def User.encrypt(token)
    Digest::SHA1.hexdigest(token.to_s)
  end

  def feed
    # このコードは準備段階です。
    # 完全な実装は第11章「ユーザーをフォローする」を参照してください。
     microposts
    #Micropost.where("user_id = ?", id)
  end

  private

    def create_remember_token
      self.remember_token = User.encrypt(User.new_remember_token)
    end
end
