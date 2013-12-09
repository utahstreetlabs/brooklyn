require 'spec_helper'

describe Users::TopFeedListings do
  class TopFeedListingsUser
    include Users::TopFeedListings
  end

  subject do
    u = TopFeedListingsUser.new
    u.stubs(:id).returns(87)
    u
  end

  let(:user) { stub_user('Corey Feldman') }

  let(:liked_listing) { FactoryGirl.create(:active_listing) }
  let(:liked_liker) { 100 }
  let(:liked_story) { story(type: :listing_liked, listing_id: liked_listing.id, actor_id: liked_liker) }

  let(:multi_action_listing) { FactoryGirl.create(:active_listing) }
  let(:multi_action_liker) { 101 }
  let(:multi_action_story) { story(type: :listing_multi_action, listing_id: multi_action_listing.id, types: ['listing_liked', 'listing_shared'], actor_id: multi_action_liker) }

  let(:multi_actor_listing) { FactoryGirl.create(:active_listing) }
  let(:multi_actor_likers) { [102, 103] }
  let(:multi_actor_story) { story(type: :listing_multi_actor, listing_id: multi_actor_listing.id, actor_ids: multi_actor_likers, action: 'listing_liked') }

  let(:multi_actor_multi_action_listing) { FactoryGirl.create(:active_listing) }
  let(:multi_actor_multi_action_likers) { [104, 105] }
  let(:multi_actor_multi_action_story) { story(type: :listing_multi_actor_multi_action, listing_id: multi_actor_multi_action_listing.id, types: {'listing_liked' => multi_actor_multi_action_likers, 'listing_shared' => [106]}) }

  let(:multi_listing_listings) { [FactoryGirl.create(:active_listing), FactoryGirl.create(:active_listing)] }
  let(:multi_listing_liker) { 107 }
  let(:multi_listing_story) { story(type: :actor_multi_listing, listing_ids: multi_listing_listings.map(&:id), action: 'listing_liked', actor_id: multi_listing_liker) }

  let(:already_liked_listing) { FactoryGirl.create(:active_listing) }
  let(:existing_likes) { [stub('existing like', listing_id: already_liked_listing.id)] }
  let(:already_liked_story) { story(type: :listing_liked, listing_id: already_liked_listing.id, actor_id: 108) }

  let(:duplicate_seller_listing) { FactoryGirl.create(:active_listing, seller: liked_listing.seller) }
  let(:duplicate_seller_story) { story(type: :listing_liked, listing_id: duplicate_seller_listing.id, actor_id: 109) }

  let(:feed_listings) { [liked_story, multi_action_story, multi_actor_story, multi_actor_multi_action_story, multi_listing_story, already_liked_story, duplicate_seller_story] }

  before do
    StoryFeeds::CardFeed.stubs(:find_slice).returns(feed_listings)
    subject.stubs(:likes).returns(existing_likes)
  end

  describe '#top_feed_listings' do
    it 'includes listings from listing_liked stories' do
      subject.top_feed_listings.keys.should include(liked_listing)
      subject.top_feed_listings[liked_listing].should == set(liked_liker)
    end

    it 'includes listings from listing_multi_action stories' do
      subject.top_feed_listings.keys.should include(multi_action_listing)
      subject.top_feed_listings[multi_action_listing].should == set(multi_action_liker)
    end

    it 'includes listings from listing_multi_actor stories' do
      subject.top_feed_listings.keys.should include(multi_actor_listing)
      subject.top_feed_listings[multi_actor_listing].should == set(*multi_actor_likers)
    end

    it 'includes listings from listing_multi_actor_multi_action stories' do
      subject.top_feed_listings.keys.should include(multi_actor_multi_action_listing)
      subject.top_feed_listings[multi_actor_multi_action_listing].should == set(*multi_actor_multi_action_likers)
    end

    it 'includes listings from actor_multi_listing stories' do
      tfl = subject.top_feed_listings(limit: 100)
      tfl.keys.should include(*multi_listing_listings)
      multi_listing_listings.each do |l|
        tfl[l].should == set(multi_listing_liker)
      end
    end

    it 'does not include listings the user has already liked' do
      subject.top_feed_listings.keys.should_not include(already_liked_listing)
    end

    it 'includes at most one listing per seller' do
      subject.top_feed_listings.keys.should_not include(duplicate_seller_listing)
    end
  end

  def story(params = {})
    Story.new_from_rising_tide(FactoryGirl.build(:rt_story, params))
  end

  def set(*args)
    Set.new(args)
  end
end
