require './acceptance/spec_helper'

feature "Complete an order", %q{
  As a buyer
  When I have received an item I purchased
  I want to confirm that the order is complete
} do

  let!(:order) { given_order(:delivered) }

  scenario "complete order from listing" do
    login_as order.buyer.email
    visit listing_path(order.listing)
    page.should have_content('Your order has been delivered')
    click_on 'Complete'
    page.should have_content('The order has been completed')
  end
end
