require 'spec_helper'

describe User do

  # 事前処理
  before do
    @user = User.new(name: "Example User", email: "user@example.com",
                     password: "foobar", password_confirmation: "foobar")
  end

  # it内のshouldのレシーバとして設定
  # @user.should ---> should
  subject { @user }

  # 属性の存在テスト
  it { should respond_to(:name) }
  it { should respond_to(:email) }
  it { should respond_to(:password_digest) }
  it { should respond_to(:password) }
  it { should respond_to(:password_confirmation) }
  it { should respond_to(:remember_token) }
  it { should respond_to(:authenticate) }
  it { should respond_to(:admin) }
  it { should respond_to(:microposts) }
  it { should respond_to(:feed) }
  it { should respond_to(:relationships) }
  it { should respond_to(:followed_users) }
  it { should respond_to(:reverse_relationships) }
  it { should respond_to(:followers) }
  it { should respond_to(:following?) }
  it { should respond_to(:follow!) }

  # 妥当性チェック
  it { should be_valid }       # @user.valid? と同じ
  it { should_not be_admin }   # !@user.admin? と同じ

  # blankを設定後、妥当性チェックが失敗することを確認
  describe "when name is not present" do
    before { @user.name = " " }
    it { should_not be_valid }
  end

  # blankを設定後、妥当性チェックが失敗することを確認
  describe "when email is not present" do
    before { @user.email = " " }
    it { should_not be_valid }
  end

  # 文字数チェック
  describe "when name is too long" do
    before { @user.name = "a" * 51 }
    it { should_not be_valid }
  end

  # 小文字変換チェック
  describe "email address with mixed case" do
    let(:mixed_case_email) { "Foo@ExAMPle.CoM" }
    it "should be saved as all lower-case" do
      @user.email = mixed_case_email
      @user.save
      expect(@user.reload.email).to eq mixed_case_email.downcase
    end
  end

  # フォーマットチェック
  # 誤っているメールアドレス
  describe "when email format is invalid" do
    it "should be invalid" do
      addresses = %w[user@foo,com user_at_foo.org example.user@foo.
                     foo@bar_baz.com foo@bar+baz.com foo@bar..com]
      addresses.each do |invalid_address|
        @user.email = invalid_address
        expect(@user).not_to be_valid
      end
    end
  end
  # 正しいメールアドレス
  describe "when email format is valid" do
    it "should be valid" do
      addresses = %w[user@foo.COM A_US-ER@f.b.org frst.lst@foo.jp a+b@baz.cn]
      addresses.each do |valid_address|
        @user.email = valid_address
        expect(@user).to be_valid
      end
    end
  end

  # 一意性チェック
  describe "when email address is already taken" do
    before do
      user_with_same_email = @user.dup
      user_with_same_email.email = @user.email.upcase
      user_with_same_email.save
    end

    it { should_not be_valid }
  end

  # blankを設定後、妥当性チェックが失敗することを確認
  describe "when password is not present" do
    before do
      @user = User.new(name: "Example User", email: "user@example.com",
                       password: " ", password_confirmation: " ")
    end
    it { should_not be_valid }
  end

  # パスワード不一致チェック
  describe "when password doesn't match confirmation" do
    before { @user.password_confirmation = "mismatch" }
    it { should_not be_valid }
  end

  # パスワード長さチェック
  describe "with a password that's too short" do
    before { @user.password = @user.password_confirmation = "a" * 5 }
    it { should be_invalid }
  end

  # 認証メソッドチェック
  describe "return value of authenticate method" do
    before { @user.save }
    let(:found_user) { User.find_by(email: @user.email) }
    describe "with valid password" do
      it { should eq found_user.authenticate(@user.password) }
    end
    describe "with invalid password" do
      let(:user_for_invalid_password) { found_user.authenticate("invalid") }
      it { should_not eq user_for_invalid_password }
      specify { expect(user_for_invalid_password).to be_false }
    end
  end

  # session用のtokenテスト
  describe "remember token" do
    before { @user.save }
    its(:remember_token) { should_not be_blank }   # its -> it(@user) の属性(:remenber_token)をさす
  end

  # マイクロポスト関連のテスト
  describe "micropost associations" do
    # @user保存
    before { @user.save }
    # let  は参照されたときに初期化
    # let! は即座に作成
    let!(:older_micropost) do
      FactoryGirl.create(:micropost, user: @user, created_at: 1.day.ago)
    end
    let!(:newer_micropost) do
      FactoryGirl.create(:micropost, user: @user, created_at: 1.hour.ago)
    end

    # Action Record の Collection Proxy から to_a で配列にして、比較
    it "should have the right microposts in the right order" do
      expect(@user.microposts.to_a).to eq [newer_micropost, older_micropost]
    end

    # マイクロポストの削除のテスト
    it "should destroy associated microposts" do
      # オブジェクトをコピー
      microposts = @user.microposts.to_a
      # ユーザを削除
      @user.destroy
      # to_a の設定忘れを回避
      expect(microposts).not_to be_empty
      # micropostが1件も無いことを確認
      microposts.each do |micropost|
        expect(Micropost.where(id: micropost.id)).to be_empty
      end
      # 1件も無いことをfindで確認する場合
      #expect do
      #  Micropost.find(micropost)
      #end.to raise_error(ActiveRecord::RecordNotFound)
    end

    describe "status" do
      # フォローしていないユーザのマイクロポストを作成
      let(:unfollowed_post) do
        FactoryGirl.create(:micropost, user: FactoryGirl.create(:user))
      end
      # ユーザ followed_user の作成
      let(:followed_user) { FactoryGirl.create(:user) }
      before do
        # followed_userをフォロー
        @user.follow!(followed_user)
        # followed_userのマイクロポストを作成
        3.times { followed_user.microposts.create!(content: "Lorem ipsum") }
      end
      # feedに自分の新しいマイクロポストがあることを確認
      its(:feed) { should include(newer_micropost) }
      # feedに自分の古いマイクロポストがあることを確認
      its(:feed) { should include(older_micropost) }
      # feedにフォローしていないユーザのマイクロポストがないことを確認
      its(:feed) { should_not include(unfollowed_post) }
      # feedにフォローしているユーザのマイクロポストがあることを確認
      its(:feed) do
        followed_user.microposts.each do |micropost|
          should include(micropost)
        end
      end
    end
  end

  describe "following" do
    let(:other_user) { FactoryGirl.create(:user) }
    before do
      @user.save
      @user.follow!(other_user)
    end
    # other_user がフォローしていることを確認
    it { should be_following(other_user) }                # 登録されているか確認
    its(:followed_users) { should include(other_user) }   # followed_users に含まれていることを確認
    # other_user からみて user をフォローしていることを確認
    describe "followed user" do
      subject { other_user }
      its(:followers) { should include(@user) }
    end
    # フォロー解除
    describe "and unfollowing" do
      before { @user.unfollow!(other_user) }
      # 解除されていることを確認
      it { should_not be_following(other_user) }
      its(:followed_users) { should_not include(other_user) }
    end
    # ユーザ削除後、Relationship からデータがなくなっていることを確認
    it "should destroy associated relationships" do
      relationships = @user.relationships.to_a
      @user.destroy
      relationships.should_not be_empty
      relationships.each do |relationship|
        expect(Relationship.where(id: relationship.id)).to be_empty
      end
    end
  end
end
