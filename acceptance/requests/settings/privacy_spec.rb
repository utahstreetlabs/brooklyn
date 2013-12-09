require './acceptance/spec_helper'

feature "Change privacy settings" do
  if feature_enabled?(:feedback)
    background do
      user = login_as "starbuck@galactica.mil"
      visit settings_privacy_path
    end

    scenario "Make purchase details private" do
      page.should have_checked_field('privacy_purchase_details_false')
      choose('privacy_purchase_details_true')
      click_button 'Save changes'
      flash_notice.should have_content("Your privacy settings have been updated")
      page.should have_checked_field('privacy_purchase_details_true')
    end
  end
end
