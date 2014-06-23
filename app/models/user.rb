class User < ActiveRecord::Base
  # 事前に小文字に変換
  before_save { self.email = email.downcase }

  validates :name,  presence:true, length: { maximum: 50 }

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence:true, format: { with: VALID_EMAIL_REGEX },
  				uniqueness: { case_sensitive: false }

  has_secure_password     # Rails 3.1からのパスワード機構
  validates :password, length: { minimum: 6 }
end
