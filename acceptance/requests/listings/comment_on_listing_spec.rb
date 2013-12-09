require './acceptance/spec_helper'

feature "Comment on a listing", %q{\n
  As someone interested in a product
  To engage in conversation about that item
  I want to comment on the item
} do

  include_context 'viewing my dashboard'

  scenario "Comment on listing", js: true do
    listing = given_listing
    visit listing_path(listing)
    comment = 'This is a comment.'
    post_listing_comment(comment)
    retry_expectations do
      page.should have_content(comment)
    end
  end
end
