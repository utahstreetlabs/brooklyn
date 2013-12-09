require './acceptance/spec_helper'

feature "View a user's profile" do
  let!(:profile_user) { given_registered_user email: 'apollo@galactica.mil' }

  scenario "I should see the user's listings for sale" do
    for_sale = [given_listing(seller: profile_user.email)]
    visit public_profile_path(profile_user)
    page.should have(for_sale.size).product_card
  end

  scenario "I should see the user's collections" do
    # user has default collections so no need to create more
    profile_user.collections.each do |collection|
      collection.add_listing(given_listing)
    end
    visit public_profile_collections_path(profile_user)
    page.should have(profile_user.collections_count).collection_cards
    page.should have(profile_user.collections_count).listing_photos
  end

  scenario "I should see the user's collection" do
    # user has default collections so no need to create more
    collection = profile_user.collections.first
    collection.add_listing(given_listing)
    visit public_profile_collection_path(profile_user, collection)
    page.should have(1).product_card
  end

  scenario "I should see the user's liked listings and tags" do
    liked_listings = [given_listing, given_listing]
    liked_listings.each { |listing| given_like(listing, profile_user) }
    liked_tags = given_tags ['rhythm', 'blues']
    liked_tags.each { |tag| given_tag_like(tag, profile_user) }
    visit liked_public_profile_path(profile_user)
    page.should have(liked_listings.size).product_cards
    page.should have(liked_tags.size).tag_cards
  end

  scenario "I should see the collections the user is following" do
    collection = given_collection
    profile_user.follow_collection!(collection)
    visit collections_public_profile_following_path(profile_user)
    page.should have(1).collection_card
  end

  scenario "I should see the people the user is following" do
    followings = 2.times.map { given_organic_follow(given_registered_user, profile_user) }
    visit people_public_profile_following_path(profile_user)
    page.should have(followings.size).user_cards
  end

  scenario "I should see the user's followers", js: true do
    follows = [given_organic_follow(profile_user, given_registered_user)]
    visit followers_public_profile_path(profile_user)
    page.should have(follows.size).user_cards
  end

  context "protected actions", js: true do
    include_context 'buyer signup'
    include_context 'with disconnected facebook test user'

    before do
      given_facebook_profile
      visit root_path
      fb_user_login
    end

    scenario "Following the profile user should send me through buyer signup and return me to the profile page" do
      pending "this isn't currently possible with forced_registration on, re-enable when we let some users do this"
      visit public_profile_path(profile_user)
      follow_profile_user
      click_facebook_signup
      add_copious_to_facebook
      proceed_through_buyer_flow
      should_be_on_profile_page
    end

    scenario "Following a follower should send me through buyer signup and return me to the followers page" do
      pending "this isn't currently possible with forced_registration on, re-enable when we let some users do this"
      follows = [given_organic_follow(profile_user, given_registered_user)]
      visit followers_public_profile_path(profile_user)
      follow_follower(follows.first.follower)
      click_facebook_signup
      add_copious_to_facebook
      proceed_through_buyer_flow
      should_be_on_followers_page
    end
  end

  context 'when logged in' do
    background do
      login_as "starbuck@galactica.mil"
    end

    if feature_enabled?(:feedback)
      scenario "I should see the user's selling feedback" do
        sold_listings = FactoryGirl.create_list(:active_listing, 2, seller: profile_user)
        sold_orders = sold_listings.map {|listing| given_order(:complete, listing: listing)}
        listings_with_cancelled_orders = FactoryGirl.create_list(:active_listing, 2, seller: profile_user)
        cancelled_orders = listings_with_cancelled_orders.map { |l| given_order_cancelled_due_to_non_shipment(listing: l) }
        visit selling_public_profile_feedback_index_path(profile_user)
        page.should have((sold_orders + cancelled_orders).size).user_feedbacks
      end

      scenario "I should see the user's buying feedback" do
        bought_orders = (1..2).map { |n| given_order(:complete, buyer: profile_user) }
        cancelled_orders = 2.times.map { given_order_cancelled_due_to_non_shipment(buyer: profile_user) }
        visit buying_public_profile_feedback_index_path(profile_user)
        page.should have(bought_orders.size).user_feedbacks
      end
    end

    scenario "I should be able to like and unlike a listing for sale", js: true do
      for_sale = [given_listing(seller: profile_user.email)]
      listing = for_sale.first
      visit public_profile_path(profile_user)
      like_product_card(listing)
      product_card_should_be_liked(listing)
      unlike_product_card(listing)
      product_card_should_not_be_liked(listing)
    end
  end

  def follow_profile_user
    within '[data-role=profile-follow-box]' do
      find('[data-action=follow]').click
    end
  end

  def follow_follower(user)
    within "[data-role=user-strip] [data-user='#{user.id}']" do
      find('[data-action=follow]').click
    end
  end

  def should_be_on_profile_page
    current_path.should == public_profile_path(profile_user)
  end

  def should_be_on_followers_page
    current_path.should == followers_public_profile_path(profile_user)
  end
end
