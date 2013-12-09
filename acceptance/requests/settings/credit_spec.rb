require './acceptance/spec_helper'

feature "View credits" do
  background do
    login_as "starbuck@galactica.mil"
    given_credits({amount: 10}, {amount: 30, expires_at: Time.now - 30})
    visit settings_profile_path
    click_link 'My Credits'
  end

  scenario "view credits" do
    page.should have_content('Available Credits')
    page.should have_content('Total credits earned: $40.00')
    within('.credits_amount') { page.should have_content('$10.00') }
    page.should have(2).credits
    page.should_not have_content('Sign up Bonus')
  end
end
