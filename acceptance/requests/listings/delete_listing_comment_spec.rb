require './acceptance/spec_helper'

feature "Delete a listing comment" do
  let!(:listing) { given_listing }

  background do
    login_as 'starbuck@galactica.mil', admin: true
  end

  scenario "delete my own comment", js: true do
    visit listing_path(listing)
    post_listing_comment
    delete_listing_comment
    delete_should_succeed
  end

  scenario "delete another person's comment", js: true do
    commenter = given_registered_user
    comment = given_comment listing, commenter
    visit listing_path(listing)
    delete_listing_comment comment
    delete_should_succeed
  end

  def delete_should_succeed
    wait_a_while_for do
      page.should have_content('This comment has been removed')
    end
  end
end
