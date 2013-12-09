require './acceptance/spec_helper'

feature "Featured listings for feature lists" do
  let(:feature_list) { given_feature_list('Board Games') }
  let(:listing1) { given_listing(title: 'Titan') }
  let(:listing2) { given_listing(title: 'Iron Dragon') }

  background do
    # feature in reverse order so listing1 is at position1 and listing2 is in position2
    feature_list.feature(listing2)
    feature_list.feature(listing1)
    login_as('starbuck@galactica.mil', admin: true)
  end

  scenario "Remove a featured listing", js: true do
    visit admin_feature_list_path(feature_list.slug)
    remove_listing(listing1)
    listing_should_be_gone(listing1)
  end

  scenario "Reorder featured listings", js: true do
    visit admin_feature_list_path(feature_list.slug)
    move_listing_to_top(listing2)
    listings_should_be_in_order(listing2, listing1)
  end
end
