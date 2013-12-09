require 'spec_helper'
require 'timecop'

describe Shipments::CheckDeliveryStatusJob do
  let(:order) { FactoryGirl.create(:shipped_order) }
  subject { order.shipment }

  before do
    # ensure the shipment is old enough to be checkable
    subject.update_column(:created_at, 1.week.ago)
    # don't use our dummy tracking number because that will skip the carrier api call and we want to stub the carrier
    # service's response
    subject.update_column(:tracking_number, '1Z12345E0205271688')
  end

  context "when the item has entered the carrier's system" do
    context "and has been delivered" do
      before do
        subject.carrier.stubs(:delivered?).with(subject.tracking_number).returns(true)
        Shipments::CheckDeliveryStatusJob.perform
        subject.reload
      end

      its(:delivery_status_checked_at) { should be > 1.minute.ago }
      it { should be_delivered }
    end

    context "but has not been delivered" do
      before do
        subject.carrier.stubs(:delivered?).with(subject.tracking_number).returns(false)
        Shipments::CheckDeliveryStatusJob.perform
        subject.reload
      end

      its(:delivery_status_checked_at) { should be > 1.minute.ago }
      it { should_not be_delivered }
    end
  end

  context "when the item has not yet entered the carrier's system" do
    before do
      # set the shipment creation timestamp so the shipment is old enough for a delivery check but still falls under
      # the threshold where we consider the carrier service to have had time to begin tracking the shipment
      subject.update_column(:created_at, 16.hours.ago)
      subject.carrier.stubs(:delivered?).with(subject.tracking_number).raises(ActiveMerchant::Shipping::ResponseError)
      Shipments::CheckDeliveryStatusJob.perform
      subject.reload
    end

    its(:delivery_status_checked_at) { should be > 1.minute.ago }
    it { should_not be_delivered }
  end
end
