require 'spec_helper'

describe Users::WhoToFollow do
  before { FactoryGirl.create(:global_interest) }

  describe ".follow_suggestions" do
    let!(:users) do
      users = (1..3).map do |i|
        user = FactoryGirl.create(:user_suggestion, interest: Interest.global).user
        FactoryGirl.create(:user_interest, user: user, interest: Interest.global)
        user
      end
      # fourth user does not have a shared interest
      users << FactoryGirl.create(:user_suggestion).user
      users
    end

    let!(:blacklisted_user) do
      user = FactoryGirl.create(:user_suggestion, interest: Interest.global).user
      FactoryGirl.create(:user_interest, user: user, interest: Interest.global)
      user
    end

    subject do
      user = FactoryGirl.create(:registered_user)
      FactoryGirl.create(:user_interest, user: user, interest: Interest.global)
      user
    end

    before { subject.expects(:follow_suggestion_blacklist).returns([blacklisted_user.id]) }

    it 'should return non-blacklisted users with shared interests ordered by position' do
      subject.follow_suggestions.should ==([users[0], users[1], users[2]])
    end

    it 'should not return users the current user has blocked' do
      subject.block!(users[1])
      subject.follow_suggestions.should ==([users[0], users[2]])
    end

    it 'should not return users who have blocked the current user' do
      users[0].block!(subject)
      subject.follow_suggestions.should ==([users[1], users[2]])
    end

    it 'should return N non-blacklisted users' do
      blacklisted = users[0..1]
      suggestions = subject.follow_suggestions(10, :blacklist => blacklisted.map(&:id))
      suggestions.should have(1).user
      suggestions.first.should == users[2]
    end
  end

  describe ".blacklist_follow_suggestion" do
    let(:blacklisted) { 123 }
    subject { FactoryGirl.create(:user_suggestion, interest: Interest.global).user }

    it "should call lagunitas to add to the follow suggestion blacklist" do
      preferences = stub('preferences')
      Lagunitas::Preferences.expects(:add).
        with(subject.id, :follow_suggestion_blacklist, blacklisted).returns(preferences)
      subject.blacklist_follow_suggestion(blacklisted).should == preferences
    end
  end

  describe ".follow_suggestion_blacklist" do
    let(:blacklist) { [123] }
    subject { FactoryGirl.create(:user_suggestion, interest: Interest.global).user }

    it "should call lagunitas to get the blacklist" do
      preferences = Lagunitas::Preferences.new(follow_suggestion_blacklist: blacklist)
      Lagunitas::Preferences.expects(:find).with(subject.id).returns(preferences)
      subject.follow_suggestion_blacklist.should == blacklist
    end

    it "return an empty list if the blacklist is nil" do
      preferences = Lagunitas::Preferences.new(follow_suggestion_blacklist: nil)
      Lagunitas::Preferences.expects(:find).with(subject.id).returns(preferences)
      subject.follow_suggestion_blacklist.should == []
    end
  end
end
