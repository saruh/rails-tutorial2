class Micropost < ActiveRecord::Base
  # 所属するuserの関連付け
  belongs_to :user
  default_scope -> { order('created_at DESC') }
  validates :user_id, presence: true
  validates :content, presence: true, length: { maximum: 140 }

  # 与えられたユーザーがフォローしているユーザー達のマイクロポストを返す。
  #def self.from_users_followed_by(user)
  def self.from_users_followed_by(user, params = nil)
    # followed_user_ids は 「has_many :followed_users」 から自動生成されている
    # followed_user_ids = followed_users.map(&:id)
    #followed_user_ids = user.followed_user_ids
    followed_user_ids = "SELECT followed_id FROM relationships
                         WHERE follower_id = :user_id"
    # user -> user.idとして認識される
    # プレースホルダで設定することにより followed_user_ids だけで followed_user_ids.join(',') を補ってくれている。
    # また、データベースに依存する一部の非互換性まで解消してくれるようです。
    #where("user_id IN (?) OR user_id = ?", followed_user_ids, user)
    #binding.pry
    if (params)
      where("(user_id IN (#{followed_user_ids}) OR user_id = :user_id) AND content Like :search_word", user_id: user, search_word: "%#{params[:search_word]}%")
    else
      where("user_id IN (#{followed_user_ids}) OR user_id = :user_id", user_id: user)
    end
  end

  # CSV出力
  def self.to_csv
    #headers = %w(ID 商品名 価格 作成日時 更新日時)
    headers = self.column_names
    csv_data = CSV.generate(headers: headers, write_headers: true, force_quotes: true) do |csv|
      all.each do |row|
        # UTF8のままで出力する場合（Excel出力を考えるとshift-jisかBOM付きのutf8で出力する必要がある）
        #csv << row.attributes.values_at(*self.column_names)
        # Shift_JIS の変換は旧漢字が文字化けするので、 cp932 で指定する必要がある
        #csv << row.attributes.values_at(*self.column_names).map{|v| v.to_s.encode('Shift_JIS', undef: :replace, replace: '')}
        csv << row.attributes.values_at(*self.column_names).map{|v| v.to_s.encode('cp932', undef: :replace, replace: '')}
      end
    end
  end
end