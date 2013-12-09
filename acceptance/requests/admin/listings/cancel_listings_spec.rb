require './acceptance/spec_helper'

feature "Cancel listing as admin" do
  let(:listing) { FactoryGirl.create(:active_listing) }

  background do
    login_as('starbuck@galactica.mil', admin: true)
  end

  scenario "cancels the listing" do
    visit admin_listing_path(listing.id)
    find('[data-action=cancel]').click
    page.should have_flash_message(:notice, 'admin.listings.cancelled')
  end
end
