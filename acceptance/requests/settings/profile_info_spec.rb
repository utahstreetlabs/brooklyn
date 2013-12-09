require './acceptance/spec_helper'

feature "Change profile information" do
  background do
    user = login_as "starbuck@galactica.mil"
    user.update_attribute(:web_site_enabled, true)
    visit settings_profile_path
  end

  scenario "change bio" do
    fill_in 'About', with: 'This is my rifle and this is my gun'
    click_button 'Save changes'
    flash_notice.should have_content("Your settings have been updated")
  end

  scenario "change location" do
    fill_in 'Location', with: 'San Francisco, CA'
    click_button 'Save changes'
    flash_notice.should have_content("Your settings have been updated")
  end

  scenario "change web site" do
    Net::HTTP.expects(:get_response).returns(Net::HTTPSuccess.new(mock, mock, mock))
    fill_in 'Web site', with: 'http://example.com/'
    click_button 'Save changes'
    flash_notice.should have_content("Your settings have been updated")
  end

  scenario "change web site with bogus URL" do
    fill_in 'Web site', with: 'wat'
    click_button 'Save changes'
    page.should have_css('#field_web_site.error')
  end
end
