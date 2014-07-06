require 'spec_helper'

describe Relationship do

  let(:follower) { FactoryGirl.create(:user) }
  let(:followed) { FactoryGirl.create(:user) }
  let(:relationship) { follower.relationships.build(followed_id: followed.id) }

  subject { relationship }

  it { should be_valid }

  describe "follower methods" do
    # 要素確認
    it { should respond_to(:follower) }
    it { should respond_to(:followed) }
    # 設定した内容が反映していることを確認
    its(:follower) { should eq follower }
    its(:followed) { should eq followed }
  end
  # followed_idをnilにした場合に無効になることを確認
  describe "when followed id is not present" do
    before { relationship.followed_id = nil }
    it { should_not be_valid }
  end
  # follower_idをnilにした場合に無効になることを確認
  describe "when follower id is not present" do
    before { relationship.follower_id = nil }
    it { should_not be_valid }
  end
end