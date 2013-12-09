require './acceptance/spec_helper'

feature "Change password" do
  background do
    login_as "starbuck@galactica.mil"
    visit settings_password_path
  end

  scenario "successful password change" do
    fill_in 'user_current_password', with: DEFAULT_PASSWORD
    fill_in 'user_password', with: "monkey"
    fill_in 'user_password_confirmation', with: "monkey"
    click_button "Save New Password"

    current_user.should authenticate_with("monkey")
    flash_notice.should have_content("Your password has been changed")
  end

  scenario "can't update password without providing current one" do
    fill_in 'user_current_password', with: "not the password"
    fill_in 'user_password', with: "monkey"
    fill_in 'user_password_confirmation', with: "monkey"
    click_button "Save New Password"

    page.should have_content("You must enter your current password")
    current_user.should_not authenticate_with("monkey")
  end

  scenario "can't update password without confirming the new one" do
    fill_in 'user_current_password', with: DEFAULT_PASSWORD
    fill_in 'user_password', with: "monkey"
    fill_in 'user_password_confirmation', with: ""
    click_button "Save New Password"

    page.should have_content("The passwords you entered did not match")
    current_user.should_not authenticate_with("monkey")
  end

  RSpec::Matchers.define :authenticate_with do |password|
    match do |user|
      user.reload.authenticates?(password)
    end
  end
end
