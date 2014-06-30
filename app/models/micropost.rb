class Micropost < ActiveRecord::Base
  # 所属するuserの関連付け
  belongs_to :user
  default_scope -> { order('created_at DESC') }
  validates :user_id, presence: true
  validates :content, presence: true, length: { maximum: 140 }
end