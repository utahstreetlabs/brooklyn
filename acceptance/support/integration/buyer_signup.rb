module BuyerSignupHelpers
  shared_context 'buyer signup' do
    let(:tags) do
      given_tags(['Bourbon', 'Scotch', 'Vodka', 'Rum', 'Tequila', 'Mezcal'])
    end

    let(:users) do
      [given_registered_user(name: 'John Bonham'),
       given_registered_user(name: 'John Paul Jones'),
       given_registered_user(name: 'Jimmy Page'),
       given_registered_user(name: 'Robert Plant'),
       given_registered_user(name: 'Jason Bonham')]
    end

    let!(:interesting_users) do
      [given_registered_user(name: 'Jim Morrison'),
       given_registered_user(name: 'Ray Manzarek'),
       given_registered_user(name: 'Robby Krieger'),
       given_registered_user(name: 'John Densmore')]
    end

    let!(:interests) do
      given_global_interest
      given_onboarding_interests(6)
    end

    background do
      users.each do |user|
        user.add_to_autofollow_list!
      end

      interesting_users.each do |interesting_user|
        given_interest_suggestions(interesting_user)
      end

      given_listing(title: 'A H Hirsch Reserve 16 Year', tags: ['Bourbon'])
      given_listing(title: 'Bruichladdich Resurrection', tags: ['Scotch'])
      given_listing(title: 'Square One Botanical Vodka', tags: ['Vodka'])
      given_listing(title: 'Kraken Black Spiced Rum', tags: ['Rum'])
    end
  end

  shared_context 'signup credit offers exist' do
    let(:signup_offer_amount) { 30 }

    before do
      Vanity.playground.experiments[:signup_credit].alternatives.each do |alternative|
        ab_value = alternative.value
        Factory.create(:offer, amount: signup_offer_amount, ab_tag: ab_value, new_users: true, existing_users: false, signup: true)
      end
    end
  end

  def proceed_through_buyer_flow
    complete_full_registration
    proceed_through_onboarding
  end

  def proceed_through_onboarding
    unless feature_enabled?(:onboarding, :skip_interests)
      should_be_on_interests_onboarding
      like_required_number_of_interests
      continue
    end
    if !feature_enabled?(:onboarding, :follow_friends_modal) && current_user.connected_to?(:facebook)
      should_be_on_follow_friends_onboarding
      follow_friends_continue
    end
  end

  def should_be_on_interests_onboarding
    current_path.should == signup_buyer_interests_path
    page.should have(interests.count).interest_cards
    page.should have_content('Choose your interests')
  end

  def like_required_number_of_interests
    buyer_interests_likes_counter_should_require_more 5
    buyer_interests_next_button_should_be_disabled

    # like then unlike the first interest
    interest = interests.shift

    buyer_interest_should_not_be_liked interest
    like_buyer_interest interest
    buyer_interest_should_be_liked interest
    buyer_interests_likes_counter_should_require_more 4
    buyer_interests_next_button_should_be_disabled

    unlike_buyer_interest interest
    buyer_interest_should_not_be_liked interest
    buyer_interests_likes_counter_should_require_more 5
    buyer_interests_next_button_should_be_disabled

    # like each remaining interest
    interests.each_with_index do |interest, index|
      buyer_interest_should_not_be_liked interest
      like_buyer_interest interest
      buyer_interest_should_be_liked interest
      if index+1 < interests.size
        buyer_interests_likes_counter_should_require_more 5-(index+1)
        buyer_interests_next_button_should_be_disabled
      else
        buyer_interests_likes_counter_should_not_require_more
        buyer_interests_next_button_should_be_enabled
      end
    end
  end

  def buyer_interests_likes_counter_should_require_more(count)
    retry_expectations do
      buyer_interests_likes_counter_count.text.to_i.should == count
    end
  end

  def buyer_interests_likes_counter_should_not_require_more
    buyer_interests_likes_counter_should_require_more(0)
  end

  def buyer_interests_likes_counter_count
    find('.likes-counter-count')
  end

  def buyer_interests_next_button_should_be_disabled
    buyer_interests_next_button[:class].should =~ /disabled/
  end

  def buyer_interests_next_button_should_be_enabled
    buyer_interests_next_button[:class].should_not =~ /disabled/
  end

  def buyer_interests_next_button
    find('.likes-counter-button')
  end

  def like_buyer_interest(interest)
    buyer_interest_like_button(interest).click
  end

  def unlike_buyer_interest(interest)
    buyer_interest_like_button(interest).click
  end

  def buyer_interest_should_have_link(interest, path)
    retry_expectations do
      button = buyer_interest_like_button(interest)
      button.should be
      href = button[:href]
      href.should be
      # button[:href] prefixes with a scheme/host/port even though that's not what's in the page, and interests have
      # a location query param, so just check that the path is part of the href
      href.should match(path)
    end
  end

  def buyer_interest_should_be_liked(interest)
    buyer_interest_should_have_link(interest, signup_buyer_interest_unlike_path(interest))
  end

  def buyer_interest_should_not_be_liked(interest)
    buyer_interest_should_have_link(interest, signup_buyer_interest_like_path(interest))
  end

  def buyer_interest_like_button(interest)
    find("[data-interest='#{interest.id}']")
  end

  def continue
    click_on 'Continue'
  end

  def follow_friends_continue
    page.execute_script("$('#follow-friends-form').submit()")
  end

  def should_be_on_follow_friends_onboarding
    if current_user.connected_to?(:facebook)
      retry_expectations { current_path.should == signup_buyer_friends_path }
      page.should have_css('.follow-friends-container')
    else
      unless feature_enabled?(:onboarding, :autofollow_collections)
        retry_expectations { current_path.should == signup_buyer_people_path }
        user_count = current_user.interests.count * Brooklyn::Application.config.interests.cards.suggested_person_count
        page.should have_css('.user-list-container', maximum: user_count)
      end
    end
  end

  def unfollow_and_refollow_buyer_user
    user = interesting_users.first
    buyer_user_should_be_followed user
    unfollow_buyer_user user
    buyer_user_should_not_be_followed user
    follow_buyer_user user
    buyer_user_should_be_followed user
  end

  def unfollow_buyer_user(user)
    buyer_user_follow_button(user).click
  end

  def follow_buyer_user(user)
    buyer_user_follow_button(user).click
  end

  def buyer_user_should_not_be_followed(user)
    wait_a_while_for do
      buyer_user_follow_button(user).should have_content 'Follow'
    end
  end

  def buyer_user_should_be_followed(user)
    wait_a_while_for do
      buyer_user_follow_button(user).should have_content 'Following'
    end
  end

  def buyer_user_follow_button(user)
    find("#follow-button-#{user.id}")
  end

  def onboarding_redirect_should_succeed
    wait_a_while_for do
      page.has_css?('#user_email', visible: true).should be_true
    end
  end
end

RSpec.configure do |config|
  config.include BuyerSignupHelpers
end

