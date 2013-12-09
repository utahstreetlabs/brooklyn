require './acceptance/spec_helper'

feature "Featured listings for categories" do
  let(:category) { given_category('drums') }
  let(:listing1) { given_listing(title: 'Pork Pie 7x14 Cherry Bubinga 7ply Shell Snare Drum', category: category) }
  let(:listing2) { given_listing(title: 'Ludwig Speed King Single Bass Drum Pedal', category: category) }

  background do
    # feature in reverse order so listing1 is at position1 and listing2 is in position2
    category.feature(listing2)
    category.feature(listing1)
    login_as('starbuck@galactica.mil', admin: true)
  end

  scenario "Remove a featured listing", js: true do
    visit admin_category_path(category)
    remove_listing(listing1)
    listing_should_be_gone(listing1)
  end

  scenario "Reorder featured listings", js: true do
    visit admin_category_path(category)
    move_listing_to_top(listing2)
    listings_should_be_in_order(listing2, listing1)
  end
end
