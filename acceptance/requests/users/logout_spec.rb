require './acceptance/spec_helper'
require 'timecop'

feature "Logout", %q{
  As a user
  When I am done buying and selling on Copius
  I want to end my session so that bad people can not hijack it
} do

  feature_flag('hamburger', false)

  let(:user) { given_registered_user }

  scenario "log out" do
    login_as user.email
    click_link "Log out"
    expect(page).to have_content("Log In")
  end

  scenario "automatic session timeout should redirect to wherever the user was trying to go" do
    listing = FactoryGirl.create(:active_listing)
    login_as user.email, dont_remember_me: true
    wait_until_session_expires_and do
      visit listing_path(listing)
      expect(page).to have_content("Log In")
      login_as user.email
      expect(page.current_path).to eq(listing_path(listing))
    end
  end

  scenario "automatic session timeout with remember me" do
    login_as user.email
    wait_until_session_expires_and do
      visit for_sale_dashboard_path
      expect(page.current_path).to eq(for_sale_dashboard_path)
      wait_until_remember_me_expires_and do
        visit for_sale_dashboard_path
        expect(page).to have_content("Log In")
        login_as user.email
        expect(page.current_path).to eq(for_sale_dashboard_path)
      end
    end
  end

  def wait_until_session_expires_and(&b)
    Timecop.travel(Time.zone.now + Brooklyn::Application.config.session.timeout_in + 5.minutes, &b)
  end

  def wait_until_remember_me_expires_and(&b)
    Timecop.travel(Time.zone.now + Brooklyn::Application.config.session.remember_for + 5.minutes, &b)
  end
end
