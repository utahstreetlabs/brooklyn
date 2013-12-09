require "spec_helper"

describe Autoshare::UserFollowed do
  let(:followee) { stub_user 'Ian Hunter', id: 44444 }
  let(:followee_url) { 'http://clickety/click' }
  let(:follower) { stub_user 'David Bowie', id: 55555 }

  it "autoshares to the follower's networks when he follows somebody" do
    User.expects(:find).with(followee.id).returns(followee)
    User.expects(:find).with(follower.id).returns(follower)
    follower.expects(:autoshare).with(:user_followed, followee, followee_url)
    Autoshare::UserFollowed.perform(followee.id, followee_url, follower.id)
  end

  it "does not propagate an exception" do
    User.expects(:find).raises(ActiveRecord::RecordNotFound)
    follower.expects(:autoshare).never
    expect { Autoshare::UserFollowed.perform(followee.id, followee_url, follower.id) }.not_to raise_error
  end
end
