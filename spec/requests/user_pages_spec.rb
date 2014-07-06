require 'spec_helper'

describe "User pages" do

  subject { page }

  describe "index" do
    # user作成
    let(:user) { FactoryGirl.create(:user) }
    # サインインして、ユーザ一覧ページへ移動
    before do
      sign_in user
      visit users_path
    end
    # 一覧ページにきていることの確認
    it { should have_title('All users') }
    it { should have_content('All users') }
    # ページネーションの確認
    describe "pagenation" do
      # 30人分のユーザを登録
      before(:all) { 30.times { FactoryGirl.create(:user) } }
      # ユーザ情報を削除
      after(:all)  { User.delete_all }

      # html要素の確認
      it { should have_selector('div.pagination') }

      # 1ページ目のユーザリストにおいて、ユーザごとにリストタグが作成されているか確認
      it "should list each user" do
        User.paginate(page: 1).each do |user|
          expect(page).to have_selector('li', text: user.name)
        end
      end
    end

    describe "delete links" do
      # 削除リンクが無いことを確認
      it { should_not have_link('delete') }

      describe "as an admin user" do
        # 管理者作成
        let(:admin) { FactoryGirl.create(:admin) }
        # 管理者でログインして、一覧ページへ移動
        before do
          sign_in admin
          visit users_path
        end

        # 削除リンクがあることを確認
        it { should have_link('delete', href: user_path(User.first)) }
        it "should be able to delete another user" do
          # 削除リンクのクリックによってユーザの登録数が1つ減ることを確認
          expect do
            click_link('delete', match: :first)
          end.to change(User, :count).by(-1)
        end

        # 管理者の削除リンクが無いことを確認
        it { should_not have_link('delete', href: user_path(admin)) }
      end
    end

    # 管理者が自分自身を削除できないことを確認
    describe "as an admin user" do
      let(:admin) { FactoryGirl.create(:admin) }
      before { sign_in admin, no_capybara: true }
      specify "should not be able to delete themselves via #destroy action" do
        expect { delete user_path(admin) }.not_to change(User, :count).by(-1)
      end
    end
  end

  describe "profile page" do
    let(:user) { FactoryGirl.create(:user) }
    let!(:m1)  { FactoryGirl.create(:micropost, user: user, content: "Foo")}
    let!(:m2)  { FactoryGirl.create(:micropost, user: user, content: "Bar")}
    before { visit user_path(user) }

    it { should have_content(user.name) }
    it { should have_title(user.name) }

    describe "microposts" do
      it { should have_content(m1.content) }
      it { should have_content(m2.content) }
      it { should have_content(user.microposts.count) }
    end

    # 自分のマイクロポストは削除リンクが表示されることを確認
    describe "as a user" do
      before do
        sign_in user
        visit user_path(user)
      end

      it { should have_link('delete') }
    end

    # 他人にはマイクロポストの削除リンクが表示されないことを確認
    describe "as an other user" do
      let(:other_user) { FactoryGirl.create(:user) }
      before do
        sign_in other_user
        visit user_path(user)
      end

      it { should_not have_link('delete') }
    end

    describe "follow/unfollow buttons" do
      let(:other_user) { FactoryGirl.create(:user) }
      before { sign_in user }

      describe "following a user" do
        before { visit user_path(other_user) }
        # フォローされているユーザが増加することを確認
        it "should increment the followed user count" do
          expect do
            click_button "Follow"
          end.to change(user.followed_users, :count).by(1)
        end
        # フォローしているユーザが増加することを確認
        it "should increment the other user's followers count" do
          expect do
            click_button "Follow"
          end.to change(other_user.followers, :count).by(1)
        end
        # フォローした後、フォロー解除のためのボタンが表示されることを確認
        describe "toggling the button" do
          before { click_button "Follow" }
          it { should have_xpath("//input[@value='Unfollow']") }
        end
      end

      describe "unfollowing a user" do
        before do
          user.follow!(other_user)
          visit user_path(other_user)
        end

        it "should decrement the followed user count" do
          expect do
            click_button "Unfollow"
          end.to change(user.followed_users, :count).by(-1)
        end

        it "should decrement the other user's followers count" do
          expect do
            click_button "Unfollow"
          end.to change(other_user.followers, :count).by(-1)
        end

        describe "toggling the button" do
          before { click_button "Unfollow" }
          it { should have_xpath("//input[@value='Follow']") }
        end
      end
    end
  end

  describe "signup page" do
    before { visit signup_path }

    it { should have_content('Sign up') }
    it { should have_title(full_title('Sign up')) }
  end

  describe "signup" do
    before { visit signup_path }
    let(:submit) { "Create my account" }

    describe "with invalid information" do
      it "should not create a user" do
        expect { click_button submit }.not_to change(User, :count)
      end

      describe "after submission" do
        before {click_button submit}

        it { should have_title('Sign up')}
        it { should have_content('error')}
      end
    end

    describe "with valid information" do
      before do
        fill_in "Name",             with: "Example User"
        fill_in "Email",            with: "user@example.com"
        fill_in "Password",         with: "foobar"
        fill_in "Confirm Password", with: "foobar"
      end

      it "should create a user" do
        expect { click_button submit }.to change(User, :count).by(1)
      end

      describe "after submission" do
        before {click_button submit}
        let(:user) {User.find_by(email: 'user@example.com')}

        it { should have_title(user.name)}
        it { should have_selector('div.alert.alert-success', text: 'Welcome')}
      end

      describe "after saving the user" do
        before { click_button submit }
        let(:user) { User.find_by(email: 'user@example.com') }

        it { should have_link('Sign out') }
        it { should have_title(user.name) }
        it { should have_selector('div.alert.alert-success', text: 'Welcome') }
      end

    end
  end

  describe "edit" do
    let(:user) { FactoryGirl.create(:user) }
    before do
      sign_in user
      visit edit_user_path(user)
    end

    describe "page" do
      it { should have_content("Update your profile") }
      it { should have_title("Edit user") }
      it { should have_link('change', href: 'http://gravatar.com/emails') }
    end

    describe "with invalid information" do
      before { click_button "Save changes" }

      it { should have_content('error') }
    end

    describe "with valid information" do
      let(:new_name)  { "New Name" }
      let(:new_email) { "new@example.com" }
      before do
        fill_in "Name",             with: new_name
        fill_in "Email",            with: new_email
        fill_in "Password",         with: user.password
        fill_in "Confirm Password", with: user.password
        click_button "Save changes"
      end

      it { should have_title(new_name) }
      it { should have_selector('div.alert.alert-success') }
      it { should have_link('Sign out', href: signout_path) }
      specify { expect(user.reload.name).to  eq new_name }
      specify { expect(user.reload.email).to eq new_email }
    end

    describe "forbidden attributes" do
      # admin権限をつけるためのパラメータを設定
      let(:params) do
        { user: { admin: true, password: user.password,
                  password_confirmation: user.password } }
      end
      # サインインして、patchメソッドを実行
      before do
        sign_in user, no_capybara: true
        patch user_path(user), params
      end
      # admin権限にならないことを確認
      specify { expect(user.reload).not_to be_admin }
    end
  end

  describe "following/followers" do
    let(:user) { FactoryGirl.create(:user) }
    let(:other_user) { FactoryGirl.create(:user) }
    before { user.follow!(other_user) }
    # サインイン後、ページにアクセスできることを確認し、フォローしている一覧に other_user がいることを確認
    describe "followed users" do
      before do
        sign_in user
        visit following_user_path(user)
      end

      it { should have_title(full_title('Following')) }
      it { should have_selector('h3', text: 'Following') }
      it { should have_link(other_user.name, href: user_path(other_user)) }
    end
    # サインイン後、ページにアクセスできることを確認し、フォローされている一覧に user がいることを確認
    describe "followers" do
      before do
        sign_in other_user
        visit followers_user_path(other_user)
      end

      it { should have_title(full_title('Followers')) }
      it { should have_selector('h3', text: 'Followers') }
      it { should have_link(user.name, href: user_path(user)) }
    end
  end
end
