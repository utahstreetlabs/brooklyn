require 'spec_helper'

describe Listings::ReturnAddressController do
  context "#create" do
    let(:name) { 'Home'}
    let(:line1) { '199 Valencia St' }
    let(:city) { 'San Francisco' }
    let(:state) { 'CA' }
    let(:zip) { '94103' }
    let(:phone) { '(415) 255-7505' }

    context "when accessed" do
      let(:buyer) { FactoryGirl.create(:registered_user) }
      let(:listing) { FactoryGirl.create(:sold_listing) }
      
      before { listing.order = FactoryGirl.create(:confirmed_order, listing: listing, buyer: buyer) }

      context "by an anonymous user" do
        before { act_as(nil) }

        it "is not authorized" do
          remote_submit_new_address_form
          response.should be_jsend_error
          response.should be_jsend_unauthorized
        end
      end

      context "by the buyer" do
        before { act_as(buyer) }

        it "is not authorized" do
          remote_submit_new_address_form
          response.should be_jsend_error
          response.should be_jsend_unauthorized
        end
      end

      context "by an arbitrary user" do
        before { act_as(Factory.create(:registered_user)) }

        it "is not authorized" do
          remote_submit_new_address_form
          response.should be_jsend_error
          response.should be_jsend_unauthorized
        end
      end

      context "for a listing without an order" do
        before { listing.order = nil }

        it "is not authorized" do
          remote_submit_new_address_form
          response.should be_jsend_error
          response.should be_jsend_unauthorized
        end
      end

      context "as the seller" do
        before { act_as(listing.seller) }

        it "succeeds" do
          remote_submit_new_address_form
          response.should be_jsend_success
        end
      end

      def remote_submit_new_address_form(params = {})
        addr_params = {:name => name, :line1 => line1, :city => city, :state => state, :zip => zip,
          :phone => phone}.merge(params)
        xhr :post, :create, listing_id: listing.to_param, new_address: addr_params, format: :json
      end
    end
  end

  context "#update" do
    context "when accessed" do
      let(:buyer) { FactoryGirl.create(:registered_user) }
      let(:listing) { FactoryGirl.create(:sold_listing) }
      let(:address) { FactoryGirl.create(:return_address, user: listing.seller) }

      before { listing.order = FactoryGirl.create(:confirmed_order, listing: listing, buyer: buyer) }

      context "by an anonymous user" do
        before { act_as(nil) }

        it "is not authorized" do
          remote_submit_change_address_form
          response.should be_jsend_error
          response.should be_jsend_unauthorized
        end
      end

      context "by the buyer" do
        before { act_as(buyer) }

        it "is not authorized" do
          remote_submit_change_address_form
          response.should be_jsend_error
          response.should be_jsend_unauthorized
        end
      end

      context "by an arbitrary user" do
        before { act_as(Factory.create(:registered_user)) }

        it "is not authorized" do
          remote_submit_change_address_form
          response.should be_jsend_error
          response.should be_jsend_unauthorized
        end
      end

      context "for a listing without an order" do
        before { listing.order = nil }

        it "is not authorized" do
          remote_submit_change_address_form
          response.should be_jsend_error
          response.should be_jsend_unauthorized
        end
      end

      context "as the seller" do
        before { act_as(listing.seller) }

        it "succeeds" do
          remote_submit_change_address_form
          response.should be_jsend_success
        end
      end

      def remote_submit_change_address_form(params = {})
        addr_params = {:address_id => address.id}.merge(params)
        xhr :put, :update, listing_id: listing.to_param, ship_from: addr_params, format: :json
      end
    end
  end
end
