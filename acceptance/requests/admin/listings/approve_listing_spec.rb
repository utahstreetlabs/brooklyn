require './acceptance/spec_helper'

feature "Manage listing approval as admin" do
  let(:listing) { FactoryGirl.create(:active_listing) }

  background do
    login_as('starbuck@galactica.mil', admin: true)
  end

  scenario "approves the listing" do
    visit admin_listing_path(listing.id)
    find('[data-action=approve]').click
    page.should have_flash_message(:notice, 'admin.listings.approved')
  end

  scenario "disapproves the listing" do
    visit admin_listing_path(listing.id)
    find('[data-action=disapprove]').click
    page.should have_flash_message(:notice, 'admin.listings.disapproved')
  end
end
