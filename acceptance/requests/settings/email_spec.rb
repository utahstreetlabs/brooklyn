require './acceptance/spec_helper'

feature "Change email" do
  background do
    login_as "starbuck@galactica.mil"
    visit settings_email_path
  end

  scenario "successful email change" do
    fill_in 'user_email', with: "karathrace@gmail.com"
    fill_in 'user_email_confirmation', with: "karathrace@gmail.com"
    click_button "Save New Email"

    flash_notice.should have_content("Your email address has been changed")
  end

  scenario "can't update email without confirming the new one" do
    fill_in 'user_email', with: "karathrace@gmail.com"
    fill_in 'user_email_confirmation', with: ""
    click_button "Save New Email"

    page.should have_content("The email addresses you entered did not match")
  end

  scenario "opt in to follow emails" do
    check "Someone starts following me"
    click_button "Save Changes"

    page.should have_checked_field("Someone starts following me")
  end

  scenario "opt out of follow emails" do
    uncheck "Someone starts following me"
    click_button "Save Changes"

    page.should_not have_checked_field("Someone starts following me")
  end
end
