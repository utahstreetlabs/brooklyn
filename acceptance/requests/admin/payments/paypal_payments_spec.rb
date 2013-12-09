require './acceptance/spec_helper'

feature "Manage PayPal payments" do
  include_context "viewing pending paypal payment"

  scenario 'Mark payment paid' do
    payment_should_be_pending
    mark_payment_paid
    payment_should_be_paid
  end
end
