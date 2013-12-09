require 'spec_helper'

describe PaypalPayment do
  describe 'after create' do
    let(:listing) { FactoryGirl.create(:active_listing) }
    let(:paypal_account) { FactoryGirl.create(:paypal_account, default: true, user: listing.seller) }
    let(:order) { FactoryGirl.create(:pending_order, listing: listing) }
    subject { FactoryGirl.build(:paypal_payment, order: order, deposit_account: paypal_account) }

    it 'enqueues PaypalPayment::AfterCreationJob' do
      PaypalPayments::AfterCreationJob.expects(:enqueue).with(is_a(Integer))
      subject.save!
    end
  end
end
