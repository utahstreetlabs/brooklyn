require './acceptance/spec_helper'

feature "Suspend listing as admin" do
  let(:listing) { FactoryGirl.create(:active_listing) }

  background do
    login_as('starbuck@galactica.mil', admin: true)
  end

  scenario "suspends the listing" do
    visit admin_listing_path(listing.id)
    find('[data-action=suspend]').click
    page.should have_flash_message(:notice, 'admin.listings.suspended')
  end
end
