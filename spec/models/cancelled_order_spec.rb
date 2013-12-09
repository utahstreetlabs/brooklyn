require 'spec_helper'

describe CancelledOrder do
  describe 'after commit' do
    context 'when creating' do
      subject { FactoryGirl.create(:confirmed_order) }
      before { Order.any_instance.stubs(:skip_refund).returns(true) }

      it 'enqueues after creation job without failure reason' do
        CancelledOrders::AfterCreationJob.expects(:enqueue).with(is_a(Integer), has_entry(failure_reason: nil)).once
        subject.cancel!
      end

      it 'enqueues after creation job with failure reason' do
        failure_reason = Order::FailureReasons::NEVER_SHIPPED
        subject.failure_reason = failure_reason
        CancelledOrders::AfterCreationJob.expects(:enqueue).with(is_a(Integer),
          has_entry(failure_reason: failure_reason))
        subject.cancel!
      end
    end

    describe 'when updating' do
      subject { CancelledOrder.find(FactoryGirl.create(:cancelled_order).id) }

      it 'does not enqueue after creation job' do
        subject
        CancelledOrders::AfterCreationJob.expects(:enqueue).never
        sleep 1
        subject.touch
      end
    end

    describe 'when destroying' do
      subject { CancelledOrder.find(FactoryGirl.create(:cancelled_order).id) }

      it 'does not enqueue after creation job' do
        subject
        CancelledOrders::AfterCreationJob.expects(:enqueue).never
        subject.destroy
      end
    end
  end

  describe '.was_confirmed_before_cancellation?' do
    it 'returns false for a previously pending order' do
      order = FactoryGirl.create(:pending_order)
      order.cancel!
      cancelled = CancelledOrder.find(order.id)
      cancelled.was_confirmed_before_cancellation?.should be_false
    end

    it 'returns true for a previously confirmed order' do
      order = FactoryGirl.create(:confirmed_order)
      order.skip_refund = true
      order.cancel!
      cancelled = CancelledOrder.find(order.id)
      cancelled.was_confirmed_before_cancellation?.should be_true
    end
  end

  describe "#create_from_order" do
    it "saves a cancelled order with the same id as the order" do
      order = FactoryGirl.create(:confirmed_order)
      order.skip_refund = true
      order.cancel!
      CancelledOrder.find(order.id).should be
    end
  end

  describe '#create_failed_transaction_feedback!' do
    subject { CancelledOrder.find(FactoryGirl.create(:cancelled_order).id) }
    before { subject.create_failed_transaction_feedback!(:never_shipped) }

    its(:seller_rating) { subject.flag.should be_false }
    its(:buyer_rating)  { subject.flag.should be_nil }
  end
end
