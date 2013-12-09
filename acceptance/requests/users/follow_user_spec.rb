require './acceptance/spec_helper'

feature "Follow a user" do
  include_context 'suppress signup follows'

  background do
    followee = given_registered_user
    login_as "starbuck@galactica.mil"
    visit public_profile_path(followee)
  end

  scenario "successfully", js: true do
    page.should have_followers_count(0)
    click_profile_follow_button
    page.should have_followers_count(1)
  end
end

feature "Unfollow a user" do
  include_context 'suppress signup follows'

  background do
    follower = given_registered_user(email: "starbuck@galactica.mil")
    followee = given_registered_user
    given_organic_follow followee, follower
    login_as follower.email
    visit public_profile_path(followee)
  end

  scenario "Unfollow a seller", js: true do
    page.should have_followers_count(1)
    click_profile_unfollow_button
    page.should have_followers_count(0)
  end
end
