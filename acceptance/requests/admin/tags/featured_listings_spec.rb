require './acceptance/spec_helper'

feature "Featured listings for tags" do
  let(:tag) { given_tag('comics') }
  let(:listing1) { given_listing(title: 'Power Man & Iron Fist') }
  let(:listing2) { given_listing(title: 'Power Pack') }

  background do
    listing1.tags << tag
    listing2.tags << tag
    # feature in reverse order so listing1 is at position1 and listing2 is in position2
    tag.feature(listing2)
    tag.feature(listing1)
    login_as('starbuck@galactica.mil', admin: true)
  end

  scenario "Remove a featured listing", js: true do
    visit admin_tag_path(tag.id)
    remove_listing(listing1)
    listing_should_be_gone(listing1)
  end

  scenario "Reorder featured listings", js: true do
    visit admin_tag_path(tag.id)
    move_listing_to_top(listing2)
    listings_should_be_in_order(listing2, listing1)
  end
end
