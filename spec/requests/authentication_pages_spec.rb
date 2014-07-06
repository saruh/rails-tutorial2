require 'spec_helper'

describe "Authentication" do

  subject { page }

  describe "signin page" do
    before { visit signin_path }

    it { should have_content('Sign in') }
    it { should have_title('Sign in') }

    it { should_not have_link('Users')}
    it { should_not have_link('Profile') }
    it { should_not have_link('Settings') }
    it { should_not have_link('Sign out') }
    it { should have_link('Sign in') }
  end

  describe "signin" do
    before { visit signin_path }

    describe "with invalid information" do
      before { click_button "Sign in" }

      it { should have_title('Sign in') }
      #it { should have_selector('div.alert.alert-error', text: 'Invalid') }
      it { should have_error_message('Invalid') }

      it { should_not have_link('Users')}
      it { should_not have_link('Profile') }
      it { should_not have_link('Settings') }
      it { should_not have_link('Sign out') }
      it { should have_link('Sign in') }

      describe "after visiting another page" do
        before { click_link "Home" }
        #it { should_not have_selector('div.alert.alert-error') }
        it { should_not have_error_message('') }
      end
    end

    describe "with valid information" do
      let(:user) { FactoryGirl.create(:user) }
      #before { valid_signin(user) }
      before { sign_in user }

      it { should have_title(user.name) }
      it { should have_link('Users',       href: users_path) }
      it { should have_link('Profile',     href: user_path(user)) }
      it { should have_link('Settings',    href: edit_user_path(user)) }
      it { should have_link('Sign out',    href: signout_path) }
      it { should_not have_link('Sign in', href: signin_path) }

      describe "followed by signout" do
        before { click_link "Sign out" }
        it { should_not have_link('Users')}
        it { should_not have_link('Profile') }
        it { should_not have_link('Settings') }
        it { should_not have_link('Sign out') }
        it { should have_link('Sign in') }
      end
    end
  end

  describe "authorization" do
    #
    describe "for non-signed-in users" do
      # ユーザ登録
      let(:user) { FactoryGirl.create(:user) }
      # サインイン制限のかかったページへ移動
      describe "when attempting to visit a protected page" do
        # 目的ページを訪れて、飛ばされたページでログイン
        before do
          visit edit_user_path(user)
          sign_in user, no_visit_signin: true
        end
        # サインイン後の確認
        describe "after signing in" do
          # 編集ページへ遷移することを確認（フレンドリーフォーワーディング）
          it "should render the desired protected page" do
            expect(page).to have_title('Edit user')
          end
          # 再度サインインし直した時の確認
          describe "when signing in again" do
            # サインアウト後にサインインページへ移動し、サインイン
            before do
              delete signout_path
              sign_in user
            end
            # デフォルトのプロファイルページに遷移することを確認
            it "should render the default (profile) page" do
              expect(page).to have_title(user.name)
            end
          end
        end
      end

      describe "in the Microposts controller" do
        # Postアクションの実行
        describe "submitting to the create action" do
          before { post microposts_path }
          specify { expect(response).to redirect_to(signin_path) }
        end
        # Destroyアクションの実行
        describe "submitting to the destroy action" do
          before { delete micropost_path(FactoryGirl.create(:micropost)) }
          specify { expect(response).to redirect_to(signin_path) }
        end
      end

      # Sign in が必要なページのアクセス制御確認
      describe "in the Users controller" do
        # プロフィール編集ページ表示
        describe "visiting the edit page" do
          before { visit edit_user_path(user) }
          it { should have_title('Sign in') }
        end
        # プロフィール更新実行
        describe "submitting to the update action" do
          before { patch user_path(user) }
          specify { expect(response).to redirect_to(signin_path) }
        end
        # ユーザ一覧ページ表示
        describe "visiting the user index" do
          before { visit users_path }
          it { should have_title('Sign in') }
        end
        # フォロー中のユーザ一覧ページ表示
        describe "visiting the following page" do
          before { visit following_user_path(user) }
          it { should have_title('Sign in') }
        end
        # フォローしているユーザの一覧表示
        describe "visiting the followers page" do
          before { visit followers_user_path(user) }
          it { should have_title('Sign in') }
        end
        # フォロー実行
        describe "submitting to the create action" do
          before { post relationships_path }
          specify { expect(response).to redirect_to(signin_path) }
        end
        # フォロー解除実行
        describe "submitting to the destroy action" do
          before { delete relationship_path(1) }
          specify { expect(response).to redirect_to(signin_path) }
        end
      end
    end

    describe "as wrong user" do
      let(:user) { FactoryGirl.create(:user) }
      let(:wrong_user) { FactoryGirl.create(:user, email: "wrong@example.com") }
      before { sign_in user, no_capybara: true }

      describe "submitting a GET request to the Users#edit action" do
        before { get edit_user_path(wrong_user) }
        specify { expect(response.body).not_to match(full_title('Edit user')) }
        specify { expect(response).to redirect_to(root_url) }
      end

      describe "submitting a PATCH request to the Users#update action" do
        before { patch user_path(wrong_user) }
        specify { expect(response).to redirect_to(root_path) }
      end
    end

    describe "as non-admin user" do
      # ユーザ作成
      let(:user) { FactoryGirl.create(:user) }
      # 管理者ではないユーザを作成
      let(:non_admin) { FactoryGirl.create(:user) }

      # capybaraではない方法で、サインイン
      before { sign_in non_admin, no_capybara: true }

      describe "submitting a DELETE request to the Users#destroy action" do
        # DELETEメソッドを発行
        before { delete user_path(user) }
        # ルートにリダイレクトされることを確認
        specify { expect(response).to redirect_to(root_path) }
      end
    end
  end

  describe "as signed-in user" do
    let(:user) { FactoryGirl.create(:user) }
    before { sign_in user, no_capybara:true }

    # difference of root_url and root_path
    # --------------------------------------------
    # $ bundle exec rails console
    # > Loading development environment (Rails 4.1.1)
    # > irb(main):001:0> app.root_url
    # > => "http://www.example.com/"
    # > irb(main):002:0> app.root_path
    # > => "/"
    # > irb(main):003:0> exit

    describe "cannot access #new action" do
      before { get new_user_path }
      #specify { expect(response).to redirect_to(root_url) }
      specify { response.should redirect_to(root_path) }
    end

    describe "cannot access #create action" do
      before { post users_path(user) }
      #specify { expect(response).to redirect_to(root_url) }
      specify { response.should redirect_to(root_path) }
    end
  end
end
