require './acceptance/spec_helper'

feature "Connect and disconnect untyped network profile" do
  include_context 'mock twitter profile'
  include_context 'viewing networks settings'

  background do
    Rubicon::Profile.stubs(:async_sync)
  end

  scenario "connect and disconnect twitter", js: true do
    connect_to :twitter, 'Twitter'
    connection_should_succeed 'Twitter'
    disconnect_from :twitter, 'Twitter'
    disconnection_should_succeed 'Twitter'
  end
end

feature "Change network autoshare settings" do
  context "for facebook" do
    include_context 'mock facebook profile'
    include_context 'stubbed graph api'

    let(:main_window) { get_last_window }

    context "when user has not granted timeline permissions" do
      before do
        given_no_timeline_permission
      end

      context "when viewing network settings" do
        include_context 'viewing networks settings'

        before do
          page_should_be_able_to_add_timelne_permission
          check "New Listings"
        end

        scenario "user can successfully add timeline permission", js: true do
          add_facebook_timeline_for_copious
          page_should_have_timeline_success_notification
          page.should have_checked_field("New Listings")
        end

        scenario "user can decline to add timeline permission", js: true do
          decline_facebook_timeline_for_copious
          page_should_have_timeline_declined_notification
          page.should_not have_checked_field("New Listings")
        end
      end

      def page_should_be_able_to_add_timelne_permission
        page.should have_selector("[data-role='autoshare-content']")
      end

      def add_facebook_timeline_for_copious
        page.execute_script("$(document).trigger(\"facebook:connectComplete\")")
        wait_a_sec_for_selenium
      end

      def decline_facebook_timeline_for_copious
        page.execute_script("$(document).trigger(\"facebook:connectCancelled\")")
        wait_a_sec_for_selenium
      end

      def page_should_have_timeline_success_notification
        page.should have_content('Your network settings have been updated.')
      end

      def page_should_have_timeline_declined_notification
        page.should have_content('Your Facebook timeline settings have not been updated.')
      end
    end

    context "when user has granted timeline permissions" do
      before do
        given_timeline_permission
      end

      context "when viewing network settings" do
        include_context 'viewing networks settings'

        scenario "opt in to share new listings", js: true do
          check "New Listings"
          save_network_settings(:facebook)
          page.should have_checked_field("New Listings")
        end

        scenario "opt out to share new listings", js: true do
          uncheck "New Listings"
          save_network_settings(:facebook)
          page.should_not have_checked_field("New Listings")
        end
      end
    end

    def get_last_window
      page.driver.browser.window_handles.last
    end
  end

  context "for twitter" do
    include_context 'mock twitter profile'
    include_context 'viewing networks settings'

    before do
      connect_to :twitter, 'Twitter'
      connection_should_succeed 'Twitter'
    end

    # the first half of this test would be setup for the second, so just do it all in one
    scenario "opt in to and out of share new listings", js: true do
      page.should_not have_checked_field("Automatically tweet my new listings")
      check_tweet_new_listings
      save_network_settings(:twitter)
      page.should have_checked_field("Automatically tweet my new listings")
      uncheck_tweet_new_listings
      save_network_settings(:twitter)
      page.should_not have_checked_field("Automatically tweet my new listings")
    end
  end

  context "when we have connected to both facebook and twitter" do
    include_context 'with facebook test user'
    include_context 'mock twitter profile'
    include_context 'stubbed graph api'
    include_context 'viewing networks settings'

    before do
      with_mocked_oauth do
        connect_to :twitter, 'Twitter'
        connection_should_succeed 'Twitter'
      end
    end

    # the first half of this test would be setup for the second, so just do it all in one
    scenario "opt in to and out of twitter settings", js: true do
      page.should_not have_checked_field("Automatically tweet my new listings")
      check_tweet_new_listings
      save_network_settings(:twitter)
      page.should have_checked_field("Automatically tweet my new listings")
      uncheck_tweet_new_listings
      save_network_settings(:twitter)
      page.should_not have_checked_field("Automatically tweet my new listings")
    end
  end

  def check_facebook_new_listings
    within ".network-setting-facebook" do
      check "New listings"
    end
  end

  def uncheck_facebook_new_listings
    within ".network-setting-facebook" do
      uncheck "New listings"
    end
  end

  def check_tweet_new_listings
    within ".network-setting-twitter" do
      check "Automatically tweet my new listings"
    end
  end

  def uncheck_tweet_new_listings
    within ".network-setting-twitter" do
      uncheck "Automatically tweet my new listings"
    end
  end
end
