require './acceptance/spec_helper'

feature "Change listing feature lists as admin" do
  let(:listing) { FactoryGirl.create(:active_listing, title: 'YT-1300 492727ZED') }
  let(:feature_list) { given_feature_list('Star Wars Ships') }

  background do
    given_feature_lists ['Sci-Fi Ships', 'Battlestar Galactica Ships']
    feature_list.feature(listing)
    login_as('starbuck@galactica.mil', admin: true)
  end

  scenario "add a listing to a feature list", js: true do
    visit admin_listing_path(listing.id)
    open_modal(feature_lists_modal_id) do
      check 'Sci-Fi Ships'
    end
    save_modal(feature_lists_modal_id)
    current_path.should == admin_listing_path(listing.id)
    open_modal(feature_lists_modal_id) do
      page.should have_checked_field("Sci-Fi Ships")
      page.should_not have_checked_field("Battlestar Galactica Ships")
    end
  end

  scenario "remove a listing from a feature list", js: true do
    visit admin_listing_path(listing.id)
    open_modal(feature_lists_modal_id) do
      uncheck 'Star Wars Ships'
    end
    save_modal(feature_lists_modal_id)
    current_path.should == admin_listing_path(listing.id)
    open_modal(feature_lists_modal_id) do
      page.should_not have_checked_field("Star Wars Ships")
    end
  end

  def feature_lists_modal_id
    'feature_lists'
  end
end
