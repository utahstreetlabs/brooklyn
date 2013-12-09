require 'spec_helper'

describe CancelledOrderMailer do
  let(:listing) { stub_listing 'Tonka Truck' }
  let(:order) { stub_order listing }

  it "builds a created message for the buyer" do
    expect { CancelledOrderMailer.created_for_buyer(order) }.not_to raise_error
  end

  it "builds a created message for the seller" do
    expect { CancelledOrderMailer.created_for_seller(order) }.not_to raise_error
  end
end
