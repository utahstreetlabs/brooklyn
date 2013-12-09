require 'spec_helper'

describe Api::OrdersController do
  context "#index" do
    let(:user) { act_as_stub_api_consumer }
    let(:sold_by_scope) { stub('sold by scope') }
    let(:after_timestamp) { 1320037000 }
    let(:before_timestamp) { 1320038000 }

    before do
      Order.expects(:sold_by_user_with_listings).with(user.id).returns(sold_by_scope)
    end

    it "filters orders using updated_before param" do
      sold_by_scope.expects(:updated_before).with(Time.zone.at(before_timestamp))
      get :index, updated_before: before_timestamp
    end

    it "filters orders using updated_after param" do
      sold_by_scope.expects(:updated_after).with(Time.zone.at(after_timestamp))
      get :index, updated_after: after_timestamp
    end

    it "filters orders using both updated_before and updated_after param" do
      compound_scope = stub('compound scope')
      sold_by_scope.expects(:updated_after).with(Time.zone.at(after_timestamp)).returns(compound_scope)
      compound_scope.expects(:updated_before).with(Time.zone.at(before_timestamp))
      get :index, updated_before: before_timestamp, updated_after: after_timestamp
    end
  end
end
