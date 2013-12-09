require './acceptance/spec_helper'

# test credit card numbers come from https://www.balancedpayments.com/docs/testing

feature "Purchase an item", js: true do
  let!(:listing) { given_listing }
  include_context 'purchasing a listing'

  scenario "using billing address for shipping" do
    visit listing_path(listing)
    begin_purchase
    should_be_on_shipping_page(listing)
    fill_in_shipping_information(bill_to_shipping: true)
    should_be_on_payment_page(listing)
    fill_in_credit_card_information
    submit_purchase_form
    should_be_on_listing_page(listing)
    listing.order.should be_confirmed
  end

  scenario "using custom billing address" do
    visit listing_path(listing)
    begin_purchase
    should_be_on_shipping_page(listing)
    fill_in_shipping_information(bill_to_shipping: false)
    should_be_on_payment_page(listing)
    fill_in_credit_card_information
    fill_in_billing_information
    submit_purchase_form
    should_be_on_listing_page(listing)
    listing.order.should be_confirmed
  end

  scenario "when checking shipping address is billing address" do
    visit listing_path(listing)
    begin_purchase
    should_be_on_shipping_page(listing)
    fill_in_shipping_information(bill_to_shipping: false)
    should_be_on_payment_page(listing)
    fill_in_credit_card_information
    check_same_as_shipping_address
    submit_purchase_form
    should_be_on_listing_page(listing)
    listing.order.should be_confirmed
  end

  scenario "with incomplete form" do
    visit listing_path(listing)
    begin_purchase
    fill_in_shipping_information(bill_to_shipping: true)
    purchase_form_should_not_be_submittable
  end

  scenario "when card is invalid" do
    visit listing_path(listing)
    begin_purchase
    fill_in_shipping_information(bill_to_shipping: true)
    # this number is too short
    fill_in_credit_card_information(card_number: '41111')
    purchase_form_should_not_be_submittable
  end

  scenario "when card is rejected" do
    pending 'balanced is currently accepting this card? madness.'
    visit listing_path(listing)
    begin_purchase
    fill_in_shipping_information(bill_to_shipping: true)
    # this number cannot be tokenized
    fill_in_credit_card_information(card_number: '4222222222222220')
    submit_purchase_form
    card_should_be_rejected
  end

  scenario "when card is declined" do
    visit listing_path(listing)
    begin_purchase
    fill_in_shipping_information(bill_to_shipping: true)
    # this number cannot have holds placed against it
    fill_in_credit_card_information(card_number: '4444444444444448')
    submit_purchase_form
    card_should_be_declined
  end
end
