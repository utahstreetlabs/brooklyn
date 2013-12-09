require 'spec_helper'

describe Orders::FollowUpOnDeliveryNonConfirmationJob do
  subject { Orders::FollowUpOnDeliveryNonConfirmationJob }

  describe '#work' do
    it "follows up on delivery non-confirmation" do
      requested_at = Time.zone.now - Order.delivery_non_confirmation_followup_period_duration - 1.day
      order = FactoryGirl.create(:shipped_order, delivery_confirmation_requested_at: requested_at)
      order.delivery_confirmation_followed_up_at.should be_nil
      subject.work
      order.reload
      order.delivery_confirmation_followed_up_at.should be
    end
  end
end
