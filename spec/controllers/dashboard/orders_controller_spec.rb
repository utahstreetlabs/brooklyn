require 'spec_helper'

describe Dashboard::OrdersController do
  let(:order) { stub_order(stub_listing('Cat whiskers'), can_deliver?: true, handling_remaining: 4.days) }
  before { Order.stubs(:find).with(order.id.to_s).returns(order) }

  describe '.delivered' do
    it_behaves_like "xhr secured against anonymous users" do
      before { do_delivered }
    end

    it_behaves_like "xhr secured against rfbs" do
      before { do_delivered }
    end

    context "for the buyer" do
      before { act_as_stub_user user: order.buyer }

      it "marks the order delivered" do
        modal = 'modal'
        listing = 'listing'
        order.expects(:deliver!)
        Dashboard::Buyer::DeliveryConfirmedExhibit.any_instance.stubs(:render).returns(modal)
        Dashboard::Buyer::ListingExhibit.any_instance.stubs(:render).returns(listing)
        do_delivered
        response.should be_jsend_success
        response.jsend_data[:modal].should == modal
        response.jsend_data[:listingId].should == order.listing_id
        response.jsend_data[:listing].should == listing
      end
    end

    def do_delivered
      xhr :post, :delivered, order_id: order.id, format: :json
    end
  end

  describe '.not_delivered' do
    it_behaves_like "xhr secured against anonymous users" do
      before { do_not_delivered }
    end

    it_behaves_like "xhr secured against rfbs" do
      before { do_not_delivered }
    end

    context "for the buyer" do
      before { act_as_stub_user user: order.buyer }

      it "marks the order not delivered" do
        modal = 'modal'
        order.expects(:report_non_delivery!)
        Dashboard::Buyer::DeliveryNotConfirmedExhibit.any_instance.stubs(:render).returns(modal)
        do_not_delivered
        response.should be_jsend_success
        response.jsend_data[:modal].should == modal
      end
    end

    def do_not_delivered
      xhr :post, :not_delivered, order_id: order.id, format: :json
    end
  end
end
