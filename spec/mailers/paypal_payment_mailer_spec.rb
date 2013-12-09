require 'spec_helper'

describe PaypalPaymentMailer do
  let(:listing) { FactoryGirl.create(:active_listing) }
  let(:paypal_account) { FactoryGirl.create(:paypal_account, default: true, user: listing.seller) }
  let(:order) { FactoryGirl.create(:pending_order, listing: listing) }
  let(:payment) { FactoryGirl.build(:paypal_payment, order: order, deposit_account: paypal_account) }

  it "builds a created message" do
    expect { PaypalPaymentMailer.created(payment) }.to_not raise_error
  end
end
