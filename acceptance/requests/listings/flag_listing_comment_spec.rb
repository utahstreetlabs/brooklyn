require './acceptance/spec_helper'

feature "Flag a listing comment" do
  let!(:listing) { given_listing }

  context "as a regular user" do
    background do
      login_as "starbuck@galactica.mil"
    end

    scenario "flag my own comment", js: true do
      visit listing_path(listing)
      post_listing_comment text: 'Buy a Rolex!'
      flag_listing_comment
      flag_should_succeed
    end

    scenario "flag another person's comment", js: true do
      commenter = given_registered_user
      comment = given_comment(listing, commenter, text: 'Buy a Rolex!')
      visit listing_path(listing)
      flag_listing_comment
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

    scenario "flag my own comment", js: true do
      visit listing_path(listing)
      post_listing_comment text: 'Buy a Rolex!'
      flag_listing_comment
      flag_should_succeed
    end

    scenario "flag another person's comment", js: true do
      commenter = given_registered_user
      comment = given_comment(listing, commenter, text: 'Buy a Rolex!')
      visit listing_path(listing)
      flag_listing_comment
      flag_should_succeed
    end

    def flag_should_succeed
      wait_a_while_for do
        page.should have_content("This comment has been flagged by test user for spam")
      end
    end
  end
end
