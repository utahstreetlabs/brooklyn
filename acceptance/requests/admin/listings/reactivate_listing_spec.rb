require './acceptance/spec_helper'

feature "Reactivate listing as admin" do
  let(:listing) { FactoryGirl.create(:suspended_listing) }

  background do
    login_as('starbuck@galactica.mil', admin: true)
  end

  scenario "reactivates the listing" do
    visit admin_listing_path(listing.id)
    find('[data-action=reactivate]').click
    page.should have_flash_message(:notice, 'admin.listings.reactivated')
  end
end
