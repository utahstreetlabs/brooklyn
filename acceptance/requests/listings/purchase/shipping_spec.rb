require './acceptance/spec_helper'

feature "Change shipping address" do
  let!(:listing) { given_listing(price: 100, shipping: 0, seller_pays_marketplace_fee: true) }
  include_context 'purchasing a listing'

  let!(:addresses) { 3.times.map { given_shipping_address(current_user) } }

  scenario "change shipping address for a pending order" do
    visit listing_path(listing)
    begin_purchase
    should_be_on_shipping_page(listing)
    choose_shipping_address(addresses.second)
    continue_to_payment
    should_be_on_payment_page(listing)
    shipping_address_should_be_shown(addresses.second)
    edit_shipping_address
    should_be_on_shipping_page(listing)
    choose_shipping_address(addresses.third)
    continue_to_payment
    should_be_on_payment_page(listing)
    shipping_address_should_be_shown(addresses.third)
  end
end

feature "Create shipping address" do
  let!(:listing) { given_listing(price: 100, shipping: 0, seller_pays_marketplace_fee: true) }
  include_context 'purchasing a listing'

  # Test verifies that we get redirected to the payment page when creating a new
  # address
  scenario "redirects user to payment page" do
    visit listing_path(listing)
    begin_purchase
    should_be_on_shipping_page(listing)
    fill_in_shipping_information(bill_to_shipping: true)
    should_be_on_payment_page(listing)
  end
end
