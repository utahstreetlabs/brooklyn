# encoding: utf-8
require 'spec_helper'

describe CardFeed do
  describe "#initialize" do
    let(:viewer) { stub_user 'Maynard James Keenan', like_existences: {} }
    let(:actor1) { FactoryGirl.create(:registered_user) }
    let(:actor2) { FactoryGirl.create(:registered_user) }
    let(:invitee) { stub_network_profile('Björn_Borg', Network::Facebook.symbol) }
    let(:followee) { stub_user('Henry Rollins') }
    let(:shared_interest) { stub('interest') }
    let(:listing1) { FactoryGirl.create(:active_listing) }
    let(:listing2) { FactoryGirl.create(:active_listing) }
    let(:tag1) { FactoryGirl.create(:tag) }
    let(:tag2) { FactoryGirl.create(:tag) }
    let(:listing_story1) { FactoryGirl.build(:rt_story, actor_id: actor1.id, type: :listing_liked, listing_id: listing1.id) }
    let(:listing_story2) { FactoryGirl.build(:rt_story, actor_id: actor2.id, type: :listing_sold, listing_id: listing2.id) }
    let(:tag_story1) { FactoryGirl.build(:rt_story, actor_id: actor1.id, type: :tag_liked, tag_id: tag1.id) }
    let(:tag_story2) { FactoryGirl.build(:rt_story, actor_id: actor2.id, type: :tag_liked, tag_id: tag2.id) }
    let(:stories) { [listing_story1, tag_story1, listing_story2, tag_story2] }
    subject { CardFeed.new(viewer, interested_user_id: viewer.id) }

    before do
      RisingTide::CardFeed.expects(:find_slice).with(is_a(Hash)).returns(stories)
      viewer.stubs(:invite_suggestions).returns([invitee])
      viewer.stubs(:count_invitable_friends).returns(25)
      viewer.stubs(:follow_suggestions).returns([followee])
      viewer.stubs(:following_follows_for).with([followee.id]).returns([])
      viewer.stubs(:find_random_shared_interests).with([followee]).returns({followee.id => shared_interest})
      viewer.stubs(:saves_for_listings).returns([])
    end


    # setup is pretty expensive here, so stacking a bunch of tests in one example
    feature_flag('feed.follow_card.fb')
    feature_flag('feed.invite_card.fb_feed_dialog')
    feature_flag('feed.invite_card.fb_u2u_request')
    feature_flag('feed.promotion_card.secret_seller')
    feature_flag('feed.promotion_card.ios')
    it "builds a suitable presenter" do
      subject.should have(7).cards
      subject.cards[0].is_a?(FollowCard).should be_true
      subject.cards[1].is_a?(ProductCard).should be_true
      subject.cards[2].is_a?(TagCard).should be_true
      subject.cards[1].story.decorated.should == listing_story1
      subject.cards[4].is_a?(PromotionCard).should be_true
      subject.cards[6].is_a?(FacebookFacepileInviteCard).should be_true
    end
  end
end
