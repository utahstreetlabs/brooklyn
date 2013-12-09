require 'spec_helper'
require 'ostruct'

describe CarrierHelper do
  context "when getting an english version of available carriers" do
    let(:ups) { Brooklyn::Carrier.new(:ups, 'UPS', 'UPS', {}, 'http://ups.com') }
    let(:usps) { Brooklyn::Carrier.new(:usps, 'USPS', 'USPS', {}, 'http://usps.com') }
    let(:fedex) { Brooklyn::Carrier.new(:fedex, 'FedEx', 'FedEx', {}, 'http://fedex.com') }

    context "with one carrier" do
      before { Brooklyn::Carrier.expects(:available).returns([ups]) }
      it "returns a single name" do
        carrier_list_string.should == 'UPS'
      end
    end

    context "with two carriers" do
      before { Brooklyn::Carrier.expects(:available).returns([ups, usps]) }
      it "returns two names" do
        carrier_list_string.should == 'UPS or USPS'
      end
    end

    context "with three carriers" do
      before { Brooklyn::Carrier.expects(:available).returns([ups, usps, fedex]) }
      it "returns three names" do
        carrier_list_string.should == 'UPS, USPS, or FedEx'
      end
    end
  end
end
