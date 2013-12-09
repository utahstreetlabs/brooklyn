require './acceptance/spec_helper'

# This feature describes the all new NYE 2012 buyer signup flow with tag liking and user following steps. The flow
# has a fixed series of steps: Account > Tags > People. It is completely separate from the old set of registration
# flows described in registration_spec.rb and will likely replace them in the fullness of time.

feature 'Buyer signup' do
  include_context 'buyer signup'
  include_context 'signup credit offers exist'

  context 'when signing up from the home page', js: true do
    before { visit root_path }

    context 'when connecting with twitter' do
      before do
        given_twitter_profile
        click_twitter_connect
      end

      context "when follow friends modal is off" do
        feature_flag('onboarding.follow_friends_modal', false)
        scenario 'proceeds through the buyer flow and drops the user on the home page' do
          proceed_through_buyer_flow
          should_be_on_home_page
          should_be_granted_signup_credit
          follow_friends_modal_should_not_exist
        end
      end
    end

    context 'when connecting with facebook' do
      include_context 'with disconnected facebook test user'

      before do
        Person.any_instance.stubs(:minimally_connected?).returns(true)
        fb_user_login
        click_facebook_connect
        add_copious_to_facebook
      end

      context "when follow friends modal is off" do
        feature_flag('onboarding.follow_friends_modal', false)
        scenario 'proceeds through the buyer flow and drops the user on the home page' do
          proceed_through_buyer_flow
          should_be_on_home_page
          should_be_granted_signup_credit
          follow_friends_modal_should_not_exist
        end
      end

      scenario 'proceeds through the buyer flow and drops the user on the home page' do
        proceed_through_buyer_flow
        should_be_on_home_page
        follow_friends_modal_should_be_visible
      end
    end

    def should_be_granted_signup_credit
      current_user.credit_balance.should == signup_offer_amount
    end
  end

  context "with an unconnected Twitter user", js: true do
    background { send(:given_twitter_profile) }

    context "signing up when buying an item" do
      let(:listing) { FactoryGirl.create(:active_listing) }

      before do
        visit listing_path(listing)
        find('[data-action=buy]').click
        wait_a_sec_for_selenium
        click_twitter_connect
      end

      context "when follow friends modal is off" do
        feature_flag('onboarding.follow_friends_modal', false)
        scenario 'proceeds through the buyer flow and drops the user on the shipping page', js: true do
          proceed_through_buyer_flow
          retry_expectations { current_path.should == shipping_listing_purchase_path(listing) }
          follow_friends_modal_should_not_exist
        end
      end
    end
  end

  context "with a registered Twitter user" do
    background do
      u = given_registered_user email: 'hams@meat.org', network: :twitter
    end

    context "when follow friends modal is off" do
      feature_flag('onboarding.follow_friends_modal', false)
      scenario 'signing up from the home page', js: true do
        visit root_path
        click_twitter_connect
        should_be_on_home_page
        follow_friends_modal_should_not_exist
      end
    end
  end

  context "with an unconnected Facebook user", js: true do
    include_context 'with disconnected facebook test user'

    background do
      visit root_path
      fb_user_login
    end

    context "signing up when buying an item" do
      let(:listing) { FactoryGirl.create(:active_listing) }

      before do
        visit listing_path(listing)
        find('[data-action=buy]').click
        wait_a_sec_for_selenium
        click_facebook_connect
        add_copious_to_facebook
      end

      context "when follow friends modal is off" do
        feature_flag('onboarding.follow_friends_modal', false)
        scenario 'proceeds through the buyer flow and drops the user on the shipping page', js: true do
          proceed_through_buyer_flow
          should_be_on_shipping_page(listing)
          follow_friends_modal_should_not_exist
        end
      end

      scenario 'proceeds through the buyer flow and drops the user on the home page' do
        proceed_through_buyer_flow
        should_be_on_shipping_page(listing)
        follow_friends_modal_should_be_visible
      end

      def should_be_on_shipping_page(listing)
        retry_expectations { current_path.should == shipping_listing_purchase_path(listing) }
      end
    end

    context "register from a utm referred page", js: true do
      let!(:interesting_user) { given_registered_user email: 'spam@no-meat.org' }

      background do
        visit public_profile_path(interesting_user, { utm_medium: "email", utm_source: "notifications", utm_campaign: "userfollow" })
      end

      context "when follow friends modal is off" do
        feature_flag('onboarding.follow_friends_modal', false)
        scenario 'signing up from the profile page', js: true do
          click_facebook_signup
          add_copious_to_facebook
          proceed_through_buyer_flow
          should_be_on_profile_page(interesting_user)
          follow_friends_modal_should_not_exist
        end
      end
    end
  end

  def follow_friends_modal_should_be_visible
    modal_should_be_visible('follow-friends')
  end

  def follow_friends_modal_should_not_exist
    modal_should_not_exist('follow-friends')
  end
end
