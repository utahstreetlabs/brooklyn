require 'spec_helper'
require 'timecop'

describe ExpireOrders do
  describe "#perform" do
    let(:timeout) { 15 }

    let!(:order) { FactoryGirl.create(:pending_order, created_at: Time.zone.now) }

    it "expires a timed out order" do
      Order.any_instance.expects(:cancel_if_unconfirmed!)
      Timecop.travel(Time.zone.now + timeout.minutes + 5.minutes) do
        ExpireOrders.perform(timeout)
      end
    end

    it "doesn't expire a order within the timeout period" do
      Order.any_instance.expects(:cancel_if_unconfirmed!).never
      Timecop.travel(Time.zone.now + timeout.minutes - 5.minutes) do
        ExpireOrders.perform(timeout)
      end
    end

    it "doesn't expire a order if the listing isn't active" do
      order.listing.suspend!
      Order.any_instance.expects(:cancel_if_unconfirmed!).never
      Timecop.travel(Time.zone.now + timeout.minutes + 5.minutes) do
        ExpireOrders.perform(timeout)
      end
    end
  end
end
