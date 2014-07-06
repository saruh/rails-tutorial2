class User < ActiveRecord::Base
  # 複数所有するmicropostsを関連付け
  #has_many :microposts
  has_many :microposts, dependent: :destroy
  # http://railstutorial.jp/chapters/following-users?version=4.0#sec-a_problem_with_the_data_model
  has_many :relationships, foreign_key: "follower_id", dependent: :destroy
  has_many :followed_users, through: :relationships, source: :followed
  # http://railstutorial.jp/chapters/following-users?version=4.0#sec-followers
  has_many :reverse_relationships, foreign_key: "followed_id", class_name: "Relationship", dependent: :destroy
  has_many :followers, through: :reverse_relationships, source: :follower
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
    #microposts
    #Micropost.where("user_id = ?", id)
    Micropost.from_users_followed_by(self)
  end
  # other_userがrelationshipsにfollowed_idとして登録されているか確認
  def following?(other_user)
    relationships.find_by(followed_id: other_user.id)
  end
  # oher_userをrelationshipsにfollowed_idとして登録
  def follow!(other_user)
    relationships.create!(followed_id: other_user.id)
  end
  # oher_userをrelationshipsから解除
  def unfollow!(other_user)
    relationships.find_by(followed_id: other_user.id).destroy
  end

  private

    def create_remember_token
      self.remember_token = User.encrypt(User.new_remember_token)
    end
end
