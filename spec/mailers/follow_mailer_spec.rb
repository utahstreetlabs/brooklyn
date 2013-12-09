require 'spec_helper'

describe FollowMailer do
  context "builds a followed message for the followee " do
    let(:follower) { stub_mailer_user('Roger Waters', listings: [stub_listing('Careful Axe')]) }
    let(:followee) { stub_user('David Gilmour') }
    let(:follow) { stub('follow', follower: follower, followee: followee, type_code: :organic) }

    before do
      Brooklyn::UsageTracker.expects(:async_track).
        with('email_follow send', follower: follower.slug, followee: followee.slug, type: follow.type_code)
    end

    it "when the followee follows the follower" do
      followee.stubs(:following?).with(follower).returns(true)
      expect { FollowMailer.follow(follow) }.not_to raise_error
    end

    it "when the followee does not follow the follower" do
      followee.stubs(:following?).with(follower).returns(false)
      expect { FollowMailer.follow(follow) }.not_to raise_error
    end
  end
end
