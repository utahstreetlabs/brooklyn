require 'spec_helper'

describe Api::Orders::ShipmentsController do
  
  let(:token) { 'abc123' }
  let(:user) { stub('current_user', { id: 123, slug: 'current-user', person_id: 124, name: 'Tester',
    registered?: true }) }
  let(:api_config) { stub('api_config', user: user) }
  let(:order) do 
    stub('order', id: '3', listing_id: '5', ship!: nil)
  end
  let(:listing) do 
    stub('listing', id: '5')
  end
  let(:shipment) do
    stub('shipment', carrier_name = 'ups')
  end
  let(:params_hash) do 
    {"shipment"=>{"order_reference"=>"2PFV426GKF7WJKZ", "carrier"=>"UPS", "tracking_number"=>"1Z12345E0205271688"},
      "order_id"=>"2PFV426GKF7WJKZ"}
  end

  before do
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(token,'')
    request.env["HTTP_ACCEPT"] = "application/xml"
    request.env["HTTP_CONTENT_TYPE"] = "application/xml"
    ApiConfig.expects(:find_by_token).with(token, include: :user).returns(api_config)
    Order.expects(:find_by_reference_number!).returns(order)
  end

  context "index" do
    it "finds listings if shipment exists" do
      Shipment.expects(:find_by_order_id!).with('3').returns(shipment)
      Listing.expects(:find).with('5').returns(listing)
      get :index, params_hash
    end

    it "returns an exception if shipment doesn't exist" do
      Shipment.expects(:find_by_order_id!).with('3').returns(nil)
      controller.expects(:respond_to_exception)
      get :index, params_hash
    end
  end
end
