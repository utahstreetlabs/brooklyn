require './acceptance/spec_helper'

feature "Like a listing" do
  background do
    listing = FactoryGirl.create(:active_listing)
    login_as "starbuck@galactica.mil"
    visit listing_path(listing)
  end

  scenario "Like listing should succeed", js: true do
    page.should have_love_button
    love_listing
    page.should have_unlove_button
  end
end

feature "Unlike a listing" do
  background do
    liker = given_registered_user(email: "starbuck@galactica.mil")
    listing = FactoryGirl.create(:active_listing)
    given_like(listing, liker)
    login_as liker.email
    visit listing_path(listing)
  end

  scenario "Unlike listing", js: true do
    page.should have_unlove_button
    unlove_listing
    page.should have_love_button
  end
end
