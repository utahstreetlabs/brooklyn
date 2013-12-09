require './acceptance/spec_helper'

feature "Flag a listing reply" do
  let!(:listing) { given_listing }

  context "as a regular user" do
    background do
      login_as "starbuck@galactica.mil"
    end

    scenario "flag my reply to my own comment", js: true do
      visit listing_path(listing)
      post_listing_comment
      reply_to_listing_comment 'Buy a Rolex!'
      flag_listing_reply
      flag_should_succeed
    end

    scenario "flag my reply to another person's comment", js: true do
      commenter = given_registered_user
      comment = given_comment(listing, commenter)
      visit listing_path(listing)
      reply_to_listing_comment 'Buy a Rolex!'
      flag_listing_reply
      flag_should_succeed
    end

    scenario "flag another person's reply", js: true do
      commenter = given_registered_user
      comment = given_comment(listing, commenter)
      replier = given_registered_user
      reply = given_reply(comment, replier, text: 'Buy a Rolex!')
      visit listing_path(listing)
      flag_listing_reply reply
      flag_should_succeed
    end

    def flag_should_succeed
      wait_a_while_for do
        page.should have_content("The comment has been flagged")
      end
    end
  end

  context "as an admin" do
    background do
      login_as "starbuck@galactica.mil", admin: true
    end

    scenario "flag my reply to my own comment", js: true do
      visit listing_path(listing)
      post_listing_comment
      reply_to_listing_comment 'Buy a Rolex!'
      flag_listing_reply
      flag_should_succeed
    end

    scenario "flag my reply to another person's comment", js: true do
      commenter = given_registered_user
      comment = given_comment(listing, commenter)
      visit listing_path(listing)
      reply_to_listing_comment 'Buy a Rolex!'
      flag_listing_reply
      flag_should_succeed
    end

    scenario "flag another person's reply", js: true do
      commenter = given_registered_user
      comment = given_comment(listing, commenter)
      replier = given_registered_user
      reply = given_reply(comment, replier, text: 'Buy a Rolex!')
      visit listing_path(listing)
      flag_listing_reply reply
      flag_should_succeed
    end

    def flag_should_succeed
      wait_a_while_for do
        page.should have_content("This comment has been flagged by test user for spam")
      end
    end
  end
end
