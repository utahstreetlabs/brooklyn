require './acceptance/spec_helper'

feature "Delete a reply to a listing comment" do
  let!(:listing) { given_listing }

  background do
    login_as 'starbuck@galactica.mil', admin: true
  end

  scenario "delete a reply I made to my own comment", js: true do
    visit listing_path(listing)
    post_listing_comment
    reply_to_listing_comment
    delete_listing_reply
    delete_should_succeed
  end

  scenario "delete a reply I made to another person's comment", js: true do
    commenter = given_registered_user
    comment = given_comment listing, commenter
    visit listing_path(listing)
    reply_to_listing_comment
    delete_listing_reply
    delete_should_succeed
  end

  scenario "delete another person's reply", js: true do
    commenter = given_registered_user
    comment = given_comment listing, commenter
    replier = given_registered_user
    reply = given_reply comment, replier
    visit listing_path(listing)
    delete_listing_reply reply
    delete_should_succeed
  end

  def delete_should_succeed
    wait_a_while_for do
      page.should have_content('This comment has been removed')
    end
  end
end
