require 'spec_helper'

describe PaypalPayments::AfterCreationJob do
  let(:listing) { FactoryGirl.create(:active_listing) }
  let(:paypal_account) { FactoryGirl.create(:paypal_account, default: true, user: listing.seller) }
  let(:order) { FactoryGirl.create(:pending_order, listing: listing) }
  let(:payment) { FactoryGirl.build(:paypal_payment, order: order, deposit_account: paypal_account) }

  subject { PaypalPayments::AfterCreationJob }

  describe '#perform' do
    before { PaypalPayment.stubs(:find).with(payment.id).returns(payment) }

    it 'performs' do
      subject.expects(:send_email).with(:created, payment)
      subject.perform(payment.id)
    end
  end
end
