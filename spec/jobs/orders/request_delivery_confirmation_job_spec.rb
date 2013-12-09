require 'spec_helper'

describe Orders::RequestDeliveryConfirmationJob do
  subject { Orders::RequestDeliveryConfirmationJob }

  describe '#work' do
    it "requests delivery confirmation for an order whose delivery confirmation period has elapsed" do
      order = FactoryGirl.create(:shipped_order)
      order.delivery_confirmation_requested_at.should be_nil
      Timecop.travel(order.shipped_at + Order.delivery_confirmation_period_duration + 1.day) do
        subject.work
      end
      order.reload
      order.delivery_confirmation_requested_at.should be
    end
  end
end
