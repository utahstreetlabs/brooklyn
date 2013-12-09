require "spec_helper"

describe RemindPurchasedUnshippedOrder do
  subject { RemindPurchasedUnshippedOrder }
  describe '#perform' do
    let(:order_id) { 1 }
    let(:order) { stub('order', confirmed?: true, id: order_id, listing: stub('listing', seller_id: 2)) }
    before { Order.expects(:find).with(order_id).returns(order) }

    it 'sends mail, injects a notification if the order is confirmed' do
      subject.expects(:send_email)
      subject.expects(:inject_notification)
      subject.perform(order_id)
    end
  end
end
