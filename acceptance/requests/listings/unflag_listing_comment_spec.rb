require './acceptance/spec_helper'

feature "Unflag a listing comment" do
  let!(:listing) { given_listing }

  background do
    login_as "starbuck@galactica.mil", admin: true
  end

  scenario "unflag my flag of my own comment", js: true do
    visit listing_path(listing)
    post_listing_comment
    flag_listing_comment
    unflag_listing_comment
    unflag_should_succeed
  end

  scenario "unflag my flag of another person's comment", js: true do
    commenter = given_registered_user
    comment = given_comment(listing, commenter)
    visit listing_path(listing)
    flag_listing_comment comment
    unflag_listing_comment comment
    unflag_should_succeed
  end

  scenario "unflag another person's flag", js: true do
    commenter = given_registered_user
    comment = given_comment(listing, commenter)
    flagger = given_registered_user
    flag = given_comment_flag(comment, flagger)
    visit listing_path(listing)
    unflag_listing_comment comment
    unflag_should_succeed
  end

  def unflag_should_succeed
    page.should_not have_content("This comment has been flagged")
  end
end
