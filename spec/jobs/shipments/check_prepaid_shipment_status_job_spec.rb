require 'spec_helper'
require 'timecop'

describe Shipments::CheckPrepaidShipmentStatusJob do
  let!(:order) { FactoryGirl.create(:confirmed_order) }
  # don't use our dummy tracking number because that will skip the carrier api call and we want to stub the label
  # service's response
  let!(:shipping_label) { FactoryGirl.create(:shipping_label, order: order, tracking_number: '1Z12345E0205271688') }
  subject { order.shipment }

  context "when the item has been shipped" do
    before do
      SHIPPING_LABELS.shipped[shipping_label.tx_id] = true
      Shipments::CheckPrepaidShipmentStatusJob.perform
      subject.reload
    end

    its(:shipment_status_checked_at) { should be > 1.minute.ago }
    it { should be_shipped }
  end

  context "when the item has not yet been shipped" do
    before do
      SHIPPING_LABELS.shipped[shipping_label.tx_id] = false
      Shipments::CheckPrepaidShipmentStatusJob.perform
      subject.reload
    end

    its(:shipment_status_checked_at) { should be > 1.minute.ago }
    it { should_not be_shipped }
  end
end
