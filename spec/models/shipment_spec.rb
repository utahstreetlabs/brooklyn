require 'spec_helper'

describe Shipment do
  it { should normalize_attribute(:carrier_name).from(' ups  ').to('ups') }
  it { should normalize_attribute(:tracking_number).from('1Z12345E0205271688 ').to('1Z12345E0205271688') }

  it 'validates tracking number syntax by default' do
    subject = FactoryGirl.build(:shipment)
    subject.tracking_number = 'foo'
    subject.should_not be_valid
    subject.should have(1).errors_on(:tracking_number)
  end

  it 'does not validate tracking number syntax when suppressed' do
    subject = FactoryGirl.build(:shipment)
    subject.suppress_tracking_number_syntax_validation
    subject.tracking_number = 'foo'
    subject.should be_valid
  end

  let(:order) { FactoryGirl.create(:shipped_order) }
  subject { order.shipment }

  context "when finding shipments that can check delivery status" do
    before(:each) do
      subject.created_at = 2.days.ago
      subject.save!
    end

    it "can check delivery status when it shipped more than 6 hours ago and has never been refreshed" do
      Shipment.find_delivery_checkable.should have(1).order
    end

    it "can check delivery status when it shipped more than 6 hours ago and the minimum refresh period has passed" do
      subject.update_attribute(:delivery_status_checked_at, 24.hours.ago)
      Shipment.find_delivery_checkable.should have(1).order
    end

    it "can't refresh within the minimum refresh period" do
      subject.update_attribute(:delivery_status_checked_at, 2.hours.ago)
      Shipment.find_delivery_checkable.should be_empty
    end

    it "can't refresh when it shipped less than 6 hours ago" do
      subject.update_attribute(:created_at, 3.hours.ago)
      Shipment.find_delivery_checkable.should be_empty
    end

    it "can't refresh when it has already been marked delivered" do
      subject.update_attribute(:delivered_at, 3.hours.ago)
      Shipment.find_delivery_checkable.should be_empty
    end
  end

  context "when collecting tracking data from ups" do
    let(:order) { FactoryGirl.create(:shipped_order) }
    let(:carrier) { stub('carrier', key: :ups) }
    subject { order.shipment }
    before { subject.stubs(:dummy_tracking?).returns(false) }

    context "for order with 'in_transit' status at UPS" do
      before do
        carrier.stubs(:delivered?).returns(false)
        subject.stubs(:carrier).returns(carrier)
        subject.check_and_update_delivery_status!
      end

      its(:delivery_status_checked_at) { should be }
      its(:delivered?) { should be_false }
    end

    context "for order with 'delivered' status at UPS" do
      before do
        carrier.stubs(:delivered?).returns(true)
        subject.stubs(:carrier).returns(carrier)
        subject.check_and_update_delivery_status!
      end

      its(:delivered?) { should be_true }
    end
  end

  describe 'initialization' do
    it "should apply tracking number heuristics" do
      s = Shipment.new(carrier_name: :usps, tracking_number: "420941079101150134711775100763")
      s.tracking_number.should == "9101150134711775100763"
      s.valid?.should be_true
    end
  end

  describe "#check_all_delivery_statuses" do
    it "should call check_and_update_delivery_status! on all shipments, even if one fails" do
      s1 = stub('shipment 1')
      s2 = stub('shipment 2', id: 2, order_id: 12, carrier_name: 'usps', tracking_number: 'cows', created_at: Time.now - 2.days)
      s3 = stub('shipment 3', id: 3, order_id: 13, carrier_name: 'usps', tracking_number: 'hams', created_at: Time.now)
      s4 = stub('shipment 4', id: 4, order_id: 14, carrier_name: 'usps', tracking_number: 'sheeps', created_at: Time.now - 3.days)
      Shipment.expects(:find_delivery_checkable).returns([s1, s2, s3, s4])
      s1.expects(:check_and_update_delivery_status!)
      s2.expects(:check_and_update_delivery_status!).raises(ActiveMerchant::Shipping::ResponseError, "Invalid tracking number")
      s3.expects(:check_and_update_delivery_status!).raises(ActiveMerchant::Shipping::ResponseError, "No record of that item")
      s4.expects(:check_and_update_delivery_status!).raises(ActiveMerchant::Shipping::ResponseError, "Invalid tracking number")

      # should airbrake for shipment 2 and 4 because they are older than a day old, but not shipment 3 because it was just created
      Airbrake.expects(:notify).twice
      Shipment.check_all_delivery_statuses
    end
  end

  it 'should deliver shipments with the dummy ups tracking number' do
    order = FactoryGirl.create(:confirmed_order)
    order.create_shipment!(carrier_name: 'ups', tracking_number: "1Z9999999999999999")
    order.ship!
    order.shipment.check_and_update_delivery_status!
  end

  describe '.enqueue_tracking_number_update_job_if_necessary' do
    context "on save" do
      it "does not enqueue the job" do
        order = FactoryGirl.create(:confirmed_order)
        shipment = FactoryGirl.build(:shipment, order: order)
        Shipments::AfterTrackingNumberUpdateJob.expects(:enqueue).never
        shipment.save!
      end
    end

    context "on update" do
      let!(:order) { FactoryGirl.create(:shipped_order) }
      let!(:shipment) { order.shipment }

      it "enqueues the job when the tracking number has changed" do
        shipment.tracking_number = '1Z12345E0205271688'
        Shipments::AfterTrackingNumberUpdateJob.expects(:enqueue).with(shipment.id)
        shipment.save!
      end

      it "does not enqueue the job when the tracking number has not changed" do
        Shipments::AfterTrackingNumberUpdateJob.expects(:enqueue).never
        shipment.save!
      end
    end
  end
end
