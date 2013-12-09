require './acceptance/spec_helper'

feature "Apply credits to an item purchase", %q{
  As a user
  When I make a purchase
  I should be able to apply credits I have accumulated to the purchase total
} do

  let!(:listing) { given_listing(price: 100, shipping: 0, seller_pays_marketplace_fee: true) }
  include_context 'purchasing a listing'

  let!(:credit_amount) { 10 }
  let!(:credit) { given_credit(amount: credit_amount) }

  scenario "apply credits to a pending order", js: true, flakey: true do
    visit listing_path(listing)
    begin_purchase
    should_be_on_shipping_page(listing)
    apply_credit(credit_amount)
    credit_should_be_applied(listing, credit_amount)
  end

  scenario "edit credits applied to a pending order", js: true, flakey: true do
    visit listing_path(listing)
    begin_purchase
    should_be_on_shipping_page(listing)
    fill_in_shipping_information
    edit_order_details
    should_be_on_shipping_page(listing)
    apply_credit(credit_amount)
    credit_should_be_applied(listing, credit_amount)
  end
end
