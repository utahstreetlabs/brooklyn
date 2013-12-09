require './acceptance/spec_helper'

feature "Block a user", %q{\n
  As a user creeped out by another user
  To stop the other user from watching me
  I want to block the user
} do

  let!(:user) { FactoryGirl.create(:registered_user) }

  include_context 'suppress signup follows'

  scenario "Block a user", js: true do
    login_as "starbuck@galactica.mil"
    perv = given_registered_user(name: 'Gross Perv') # autofollows the current user
    given_organic_follow(current_user, perv)
    visit public_profile_path(current_user)
    wait_a_sec_for_selenium
    page.should have_followers_count(1)
    visit public_profile_path(perv)
    click_profile_block_button
    visit public_profile_path(current_user)
    wait_a_sec_for_selenium
    page.should have_followers_count(0)
  end
end
