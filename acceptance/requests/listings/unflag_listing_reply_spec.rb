require './acceptance/spec_helper'

feature "Unflag a listing reply" do
  let!(:listing) { given_listing }

  background do
    login_as "starbuck@galactica.mil", admin: true
  end

  scenario "unflag my flag of my reply to my own comment", js: true, flakey: true do
    visit listing_path(listing)
    post_listing_comment
    reply_to_listing_comment 'Buy a Rolex!'
    flag_listing_reply
    unflag_listing_reply
    unflag_should_succeed
  end

  scenario "unflag my flag of my reply to another person's comment", js: true do
    commenter = given_registered_user
    comment = given_comment(listing, commenter)
    visit listing_path(listing)
    reply_to_listing_comment 'Buy a Rolex!'
    flag_listing_reply
    unflag_listing_reply
    unflag_should_succeed
  end

  scenario "unflag my flag of another person's reply", js: true do
    commenter = given_registered_user
    comment = given_comment(listing, commenter)
    replier = given_registered_user
    reply = given_reply(comment, replier, text: 'Buy a Rolex!')
    visit listing_path(listing)
    flag_listing_reply reply
    unflag_listing_reply reply
    unflag_should_succeed
  end

  scenario "unflag another person's reply", js: true do
    commenter = given_registered_user
    comment = given_comment(listing, commenter)
    replier = given_registered_user
    reply = given_reply(comment, replier, text: 'Buy a Rolex!')
    flagger = given_registered_user
    flag = given_comment_flag(reply, flagger)
    visit listing_path(listing)
    unflag_listing_reply reply
    unflag_should_succeed
  end

  def unflag_should_succeed
    page.should_not have_content("This comment has been flagged")
  end
end
