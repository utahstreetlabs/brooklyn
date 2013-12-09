require 'spec_helper'

describe ShippingLabel do
  context '.expire' do
    subject { FactoryGirl.create(:shipping_label) }
    before { subject.expire! }

    it { should be_expired }
    its(:expired_at) { should be }
    it { subject.order.shipment.carrier_name.should be_nil }
    it { subject.order.shipment.tracking_number.should be_nil }
  end

  context ".cancel_order!" do
    subject { FactoryGirl.create(:shipping_label) }
    let!(:cancelled_order) { CancelledOrder.create_from_order(subject.order, {}) }
    before { subject.cancel_order! }

    its(:order) { should be_nil }
    its(:cancelled_order) { should == cancelled_order }
  end

  context '#find_to_expire' do
    context "when expiring before now" do
      it "finds a label expiring before now" do
        label = FactoryGirl.create(:shipping_label, expires_at: 1.day.ago)
        ShippingLabel.find_to_expire.should == [label]
      end

      it "does not find an expired label" do
        label = FactoryGirl.create(:expired_shipping_label)
        ShippingLabel.find_to_expire.should be_empty
      end

      it "does not find a label expiring after now" do
        label = FactoryGirl.create(:shipping_label, expires_at: 1.day.from_now)
        ShippingLabel.find_to_expire.should be_empty
      end

      it "does not find a label whose order is shipped" do
        label = FactoryGirl.create(:shipping_label, expires_at: 1.day.ago)
        label.order.ship!
        ShippingLabel.find_to_expire.should be_empty
      end
    end

    context "when expiring before a specified time" do
      let(:time) { Time.zone.now + 1.day }

      it "finds a label expiring before the specified time" do
        label = FactoryGirl.create(:shipping_label, expires_at: time - 1.day)
        ShippingLabel.find_to_expire(before: time).should == [label]
      end

      it "does not find an expired label" do
        label = FactoryGirl.create(:expired_shipping_label)
        ShippingLabel.find_to_expire(before: time).should be_empty
      end

      it "does not find a label expiring after the specified time" do
        label = FactoryGirl.create(:shipping_label, expires_at: time + 1.day)
        ShippingLabel.find_to_expire(before: time).should be_empty
      end

      it "does not find a label whose order is shipped" do
        label = FactoryGirl.create(:shipping_label, expires_at: time - 1.day)
        label.order.ship!
        ShippingLabel.find_to_expire(before: time).should be_empty
      end
    end
  end
end
