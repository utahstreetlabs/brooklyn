require 'spec_helper'

describe OrdersController do
  # required since response builders render partials
  render_views

  context "#ship" do
    let(:order) { FactoryGirl.create(:confirmed_order) }
    let(:tracking_number) { '1Z12345E0205271688' }

    it "requires an order" do
      remote_submit_ship_form(123, tracking_number)
      response.should be_jsend_error
      response.should be_jsend_unauthorized
    end

    context "a guest" do
      it "is not authorized to ship" do
        remote_submit_ship_form(order, tracking_number)
        response.should be_jsend_error
        response.should be_jsend_unauthorized
      end
    end

    context "not the seller" do
      let(:me) { FactoryGirl.create(:registered_user) }
      before(:each) { act_as(me) }

      it "is not authorized to ship" do
        remote_submit_ship_form(order, tracking_number)
        response.should be_jsend_error
        response.should be_jsend_unauthorized
      end
    end

    context "the seller" do
      before(:each) { act_as(order.listing.seller) }

      context "without a tracking number" do
        let(:tracking_number) { '123' }

        before(:each) { remote_submit_ship_form(order, tracking_number) }

        it "fails" do
          response.should be_jsend_failure
        end

        it "has an error for tracking number" do
          response.jsend_data['errors']['tracking_number'].should_not be_empty
        end
      end

      context "with all required parameters" do
        before(:each) { remote_submit_ship_form(order, tracking_number) }

        it "succeeds" do
          response.should be_jsend_success
        end

        it "returns a flash message" do
          response.jsend_data['message'].should_not be_empty
        end

        it "returns the listing id" do
          response.jsend_data['listingId'].should == order.listing.id
        end

        it "returns listing content" do
          response.jsend_data['listing'].should_not be_empty
        end
      end
    end

    def remote_submit_ship_form(order = nil, tracking_number = nil)
      remote_submit_form(:ship, order, shipment: {carrier_name: 'ups', tracking_number: tracking_number})
    end
  end

  context "#complete" do
    let(:order) do
      o = FactoryGirl.create(:delivered_order)
      Order.any_instance.stubs(:skip_credit).returns(true)
      o
    end

    it "requires an order" do
      remote_submit_complete_form(123)
      response.should be_jsend_error
      response.should be_jsend_unauthorized
    end

    context "a guest" do
      it "is not authorized to complete" do
        remote_submit_complete_form(order)
        response.should be_jsend_error
        response.should be_jsend_unauthorized
      end
    end

    context "not the buyer" do
      let(:me) { FactoryGirl.create(:registered_user) }
      before(:each) { act_as(me) }

      it "is not authorized to complete" do
        remote_submit_complete_form(order)
        response.should be_jsend_error
        response.should be_jsend_unauthorized
      end
    end

    context "the buyer" do
      before(:each) do
        act_as(order.buyer)
      end

      it "succeeds" do
        remote_submit_complete_form(order)
        response.should be_jsend_success
      end

      it "returns a flash message" do
        remote_submit_complete_form(order)
        response.jsend_data['message'].should_not be_empty
      end

      it "returns the listing id" do
        remote_submit_complete_form(order)
        response.jsend_data['listingId'].should == order.listing.id
      end

      it "returns listing content" do
        remote_submit_complete_form(order)
        response.jsend_data['listing'].should_not be_empty
      end
    end

    def remote_submit_complete_form(order = nil)
      remote_submit_form(:complete, order)
    end
  end

  def remote_submit_form(action, order, params = {})
    order_id = (order.is_a?(Order) ? order.id : order) if order.present?
    xhr :post, action, {:format => :json, :source => :dashboard, :order_id => order_id}.merge(params)
  end
end
