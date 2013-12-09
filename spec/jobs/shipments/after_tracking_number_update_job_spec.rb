require 'spec_helper'

describe Shipments::AfterTrackingNumberUpdateJob do
  subject { Shipments::AfterTrackingNumberUpdateJob }

  let(:listing) { stub_listing("Iron man") }
  let(:order) { stub_order(listing) }
  let(:shipment) { stub_shipment(order) }

  before { Shipment.stubs(:find).with(shipment.id).returns(shipment) }

  context 'prepaid shipping' do
    before { listing.stubs(:prepaid_shipping?).returns(true) }

    it 'does not send notifications' do
      subject.expects(:send_notifications).never
    end
  end

  context 'basic shipping' do
    before { listing.stubs(:prepaid_shipping?).returns(false) }

    it 'sends notifications' do
      subject.expects(:send_notifications).with(shipment)
      subject.perform shipment.id
    end
  end
end
