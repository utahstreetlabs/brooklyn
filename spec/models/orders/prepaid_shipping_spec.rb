require 'spec_helper'
require 'timecop'

describe Orders::PrepaidShipping do
  subject { FactoryGirl.create(:confirmed_order) }
  let!(:shipping_option) { FactoryGirl.create(:shipping_option, listing: subject.listing) }

  describe '.create_shipment_from_external_label!' do
    let(:label) { Brooklyn::ShippingLabels::Label.new(FactoryGirl.attributes_for(:shipping_label)) }

    before do
      subject.create_shipment_from_external_label!(label)
    end

    its(:shipment)       { should be }
    its(:shipment)       { subject.carrier_name.should == SHIPPING_LABELS.carrier_name }
    its(:shipment)       { subject.tracking_number.should == label.tracking_number }
  end

  describe '.create_shipping_label_from_external_label!' do
    let(:label) { Brooklyn::ShippingLabels::Label.new(FactoryGirl.attributes_for(:shipping_label)) }

    before do
      subject.create_shipping_label_from_external_label!(label)
    end

    its(:shipping_label) { should be }
    its(:shipping_label) { should be_document } # calls document? asserting that the uploader has uploaded a file
    its(:shipping_label) { subject.url.should == label.url }
    its(:shipping_label) { subject.tx_id.should == label.tx_id }
  end
end
