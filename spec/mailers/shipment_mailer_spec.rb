require 'spec_helper'

describe ShipmentMailer do
  let(:order) { FactoryGirl.create(:shipped_order) }
  let(:shipment) { order.shipment }

  it "builds a tracking number updated message for the buyer" do
    expect { ShipmentMailer.tracking_number_updated_for_buyer(shipment) }.to_not raise_error
  end

  it "builds a tracking number updated message for the seller" do
    expect { ShipmentMailer.tracking_number_updated_for_seller(shipment) }.to_not raise_error
  end
end
