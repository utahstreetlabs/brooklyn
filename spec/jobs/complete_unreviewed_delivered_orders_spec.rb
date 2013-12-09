require "spec_helper"

describe CompleteUnreviewedDeliveredOrders do

  describe "#perform" do
    let(:orders) { [stub('order 1', id: 1), stub('order 2', id: 2)] }
    before { Order.expects(:find_delivered_review_expired).returns(orders) }

    it "should complete each order" do
      orders.each { |o| o.expects(:complete_and_attempt_to_settle!) }
      CompleteUnreviewedDeliveredOrders.perform
    end

    context "when the first order throws an exception" do
      let(:exception) { Exception.new }
      before { orders.first.expects(:complete_and_attempt_to_settle!).raises(exception) }
      it "should still complete the second order" do
        orders.last.expects(:complete_and_attempt_to_settle!)
        Airbrake.expects(:notify).with(exception, {parameters: {}})
        CompleteUnreviewedDeliveredOrders.perform
      end
    end
  end
end
