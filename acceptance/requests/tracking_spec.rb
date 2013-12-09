require './acceptance/spec_helper'

# Front-to-back testing for event tracking.
#
# Verify that user actions result in tracking calls in our tracking system of choice.
#
# At the moment, this means we verify that user actions result in appropriate
# mixpanel API calls. We don't need to test every event in the system, but we should
# have enough coverage that we feel confident this is working.
feature 'User actions are tracked' do
  include_context 'tracking helpers'

  let!(:listing) { FactoryGirl.create(:active_listing) }
  let(:redis) { stub_everything('redis', keys: []) }
  let(:connection) { stub('connection', redis: redis) }

  background do
    login_as "starbuck@galactica.mil"
    Vanity.playground.stubs(:connection).returns(connection)
  end

  scenario 'listing views should be tracked in mixpanel', driver: :capybara_with_headers do
    with_live_usage_tracker do
      # don't verify everything, but distinct_id, name, and some listing properties should
      # definitely be checked for
      should_track_in_mixpanel('listing view',
        :'$browser' => 'Opera', :'$os' => 'Windows XP',
        utm_source: 'notifications', utm_campaign: 'userfollow', utm_medium: 'seance',
        name: current_user.name, email: current_user.email, distinct_id: current_user.visitor_id,
        listing_title: listing.title, seller_name: listing.seller.name, shipping_price: listing.shipping,
        total_price: listing.total_price, price: listing.price, state: 'active', platform: :web)
      visit listing_path(listing, utm_medium: 'seance', utm_source: 'notifications', utm_campaign: 'userfollow', )
    end
  end

  scenario 'bots should not be tracked', driver: :capybara_with_bot_agent do
    with_live_usage_tracker do
      Brooklyn::Mixpanel.expects(:post).never
      visit listing_path(listing)
    end
  end

  scenario 'fb_ref properties should be passed to mixpanel', driver: :capybara_with_headers do
    with_live_usage_tracker do
      should_track_in_mixpanel('listing view', {fb_foo: 'bar', fb_fuz: 'baz', fb_types: ['test1', 'test2']})
      visit listing_path(listing, fb_ref: Network::Facebook::Ref.new('test1,test2', {foo: :bar, fuz: :baz}).to_ref)
    end
  end
end
