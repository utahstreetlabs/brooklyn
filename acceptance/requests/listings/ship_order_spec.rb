require './acceptance/spec_helper'

feature "Complete an order", %q{
  As a seller
  When I have shipped off an item somebody bought from me
  I want to let the system know I have shipped it
} do

  let!(:order) { given_order(:confirmed) }

  scenario "mark order shipped from listing", js: true do
    login_as order.listing.seller.email
    visit listing_path(order.listing)
    page.should have_content('Your item has been purchased')
    select 'UPS', :from => 'shipment_carrier_name'
    fill_in 'shipment_tracking_number', :with => '1Z12345E0205271688'
    click_on 'Enter tracking number'
    page.should have_content('Your item has been shipped!')
  end
end
