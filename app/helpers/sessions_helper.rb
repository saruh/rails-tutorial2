module SessionsHelper

  def sign_in(user)
    # 新規トークンの作成
    remember_token = User.new_remember_token
    # Cookieにトークンをセット
    # cookies[:remember_token] = { value:   remember_token,
    #                              expires: 20.years.from_now.utc }
    cookies.permanent[:remember_token] = remember_token   # permanentはcookiesのユーティリティです。これで上と同意(有効期限20年)になります。
    # 暗号化したトークンをDBに保存
    user.update_attribute(:remember_token, User.encrypt(remember_token))
    # ユーザを現在のユーザとして設定（コントロールからも、ビューからもアクセスできるようになります。）
    self.current_user = user
  end

  def signed_in?
    !current_user.nil?
  end

  def current_user=(user)
    @current_user = user
  end

  def current_user
    remember_token = User.encrypt(cookies[:remember_token])
    @current_user ||= User.find_by(remember_token: remember_token)
  end

  def sign_out
    self.current_user = nil
    cookies.delete(:remember_token)
  end
end
