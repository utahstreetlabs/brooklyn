require 'spec_helper'

describe Events::Base do
  subject { Events::Base }

  describe 'property loaders' do
    let(:listing_id) { 1 }
    let(:listing) { stub_listing('50 delegate votes') }
    before { Listing.expects(:find).returns(listing) }

    describe '#listing_properties' do
      it 'should return standard listing properties for mixpanel events' do
        p = subject.listing_properties(listing_id)
        p.should have_key(:created_at)
        p.should have_key(:activated_at)
        p.should include(:seller_name=>"Mephistopheles", listing_title: "50 delegate votes",
          category: "Stuff", condition: "Hella Broken", size: "None", brand: "None", tags: [],
          total_price: 100.0, price: 100.0, buyer_fee: 1.5, seller_fee: 1.2, shipping_price: 0.0,
          handling_period: 4, platform: :web)
      end
    end

    describe '#listing_social_properties' do
      it 'should return standard listing properties for mixpanel events' do
        p = subject.listing_social_properties(listing_id)
        p.should == {loves: 1, comments: 3, saves: 4}
      end
    end
  end

  describe '#order_properties' do
    let(:order_id) { 1 }
    let(:order) { stub_order(stub_listing('50 delegate votes')) }
    before { Order.expects(:find).returns(order) }
    it 'should return standard order properties for mixpanel events' do
      p = subject.order_properties(order_id)
      p.should have_key(:purchased_at)
      p.should include(order_id: 1, buyer_name: "Joe Buyer", credits_used: 5.0)
    end
  end

  describe '#profile_properties' do
    let(:profile_id) { 1 }
    let(:profile_user) { stub_user('Janky Freebase') }
    before { User.expects(:find).returns(profile_user) }
    it 'should return standard profile properties for mixpanel events' do
      p = subject.profile_properties(profile_id)
      p.should include(profile_name: profile_user.slug,
                       profile_follower_count: profile_user.registered_followers.count,
                       profile_following_count: profile_user.registered_followees.count,
                       profile_love_count: profile_user.likes_count)
    end
  end
end
