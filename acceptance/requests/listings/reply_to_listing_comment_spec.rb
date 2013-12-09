require './acceptance/spec_helper'

feature "Reply to a listing comment", %q{\n
  As someone interested in a product
  To engage in conversation about that item
  I want to reply to a comment on the item
} do

  include_context 'viewing my dashboard'

  scenario "reply to my own comment", js: true do
    listing = given_listing
    visit listing_path(listing)
    post_listing_comment('This is a comment.')
    reply = 'Yeah dogg!'
    reply_to_listing_comment(reply)
    retry_expectations do
      page.should have_content(reply)
    end
  end
end
