require 'spec_helper'

describe OrderHelper do
  let(:status) { 'pendingd' }
  let(:order) { stub('order', status: status) }

  describe '#order_status' do
    context 'when order is delivered' do
      let(:status) { 'delivered' }

      context 'with a review period that ends in the future' do
        freeze_time(Time.new(2012, 1, 1))
        before { order.stubs(:review_period_ends_at).returns(Time.now + 1.day) }

        it 'should show when the review period ends' do
          (status, msg) = helper.order_status(order)
          msg.should == 'Review period ends in 1 day'
        end
      end

      context 'with a review period that ends in the past' do
        before { order.stubs(:review_period_ends_at).returns(Time.now - 1.day) }

        it 'should show when the review period ends' do
          (status, msg) = helper.order_status(order)
          msg.should == 'Review period has ended'
        end
      end
    end
  end
end
