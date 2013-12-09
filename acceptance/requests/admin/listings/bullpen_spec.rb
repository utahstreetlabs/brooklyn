require './acceptance/spec_helper'

feature "Listing bullpen" do
  let!(:not_yet_approved_listings) { 3.times.map { FactoryGirl.create(:active_listing, approved: nil) }   }
  let!(:unapproved_listings)       { 1.times.map { FactoryGirl.create(:active_listing, approved: false) } }
  let!(:approved_listings)         { 2.times.map { FactoryGirl.create(:active_listing, approved: true) }  }

  background do
    login_as('starbuck@galactica.mil', admin: true)
  end

  scenario "shows listings that await action" do
    visit admin_listings_bullpen_index_path
    should_have_listings(not_yet_approved_listings.size)
  end

  scenario "not yet approved listing can be approved", js: true do
    visit admin_listings_bullpen_index_path
    approve_listing(not_yet_approved_listings.first)
    listing_should_be_approved(not_yet_approved_listings.first)
  end

  scenario "not yet approved listing can be disapproved", js: true do
    visit admin_listings_bullpen_index_path
    disapprove_listing(not_yet_approved_listings.first)
    listing_should_be_disapproved(not_yet_approved_listings.first)
  end

  def should_have_listings(count)
    all('[data-listing]').count.should == count
  end

  def approve_listing(listing)
    within_listing(listing) do
      find('[data-action=approve]').click
    end
  end

  def listing_should_be_approved(listing)
    within_listing(listing) do
      page.should have_css('[data-role=approved]')
    end
  end

  def disapprove_listing(listing)
    within_listing(listing) do
      find('[data-action=disapprove]').click
    end
  end

  def listing_should_be_disapproved(listing)
    within_listing(listing) do
      page.should have_css('[data-role=disapproved]')
    end
  end

  def within_listing(listing, &block)
    within "[data-listing='#{listing.id}']" do
      yield
    end
  end
end
