require './acceptance/spec_helper'

feature 'Via bookmarklet', js: true do
  let!(:user) { given_registered_user(email: "starbuck@galactica.mil") }

  context "when user is already logged in" do
    before do
      login_as "starbuck@galactica.mil"
    end

    scenario 'create listing from an external source with a valid image', js: true do
      setup_bookmarklet_test
      bookmarklet_overlay_should_have_choices(3)
      select_overlay_image(1)
      wait_for_add_listing_popup
      add_bookmarklet_external_listing
      save_external_listing_to_collection
      wait_for_complete_window
      bookmarklet_external_listing_post_should_succeed
      logout
    end
  end

  context "when user is not logged in" do
    scenario 'create listing from an external source with a valid image', js: true do
      setup_bookmarklet_test
      bookmarklet_overlay_should_have_choices(3)
      select_overlay_image(1)
      wait_for_login_popup
      login_user_within_popup
      wait_for_add_listing_popup
      add_bookmarklet_external_listing
      save_external_listing_to_collection
      wait_for_complete_window
      bookmarklet_external_listing_post_should_succeed
      logout
    end
  end
end
