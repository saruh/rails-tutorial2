require 'spec_helper'

describe Micropost do

  let(:user) { FactoryGirl.create(:user) }
  # build -> DBに書き込まない
  before { @micropost = user.microposts.build(content: "Lorem ipsum") }

  subject { @micropost }

  # 属性を所持しているか確認
  it { should respond_to(:content) }
  it { should respond_to(:user_id) }
  it { should respond_to(:user) }
  its(:user) { should eq user }

  # @micropostの有効性を確認
  it { should be_valid }

  # user_idの有効性を確認
  describe "when user_id is not present" do
    before { @micropost.user_id = nil }
    it { should_not be_valid }
  end

  describe "with blank content" do
    before { @micropost.content = " " }
    it { should_not be_valid }
  end

  describe "with content that is too long" do
    before { @micropost.content = "a" * 141 }
    it { should_not be_valid }
  end
end