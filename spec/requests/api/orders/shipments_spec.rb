require 'spec_helper'

describe 'Create shipment' do
  let(:user) { FactoryGirl.create(:registered_user) }
  let(:listing) { FactoryGirl.create(:active_listing, seller: user) }
  let(:order) { FactoryGirl.create(:confirmed_order, listing: listing) }

  context 'with valid credentials' do
    let(:api_config) { FactoryGirl.create(:api_config, user: user) }
    let(:params) { {access_token: api_config.token} }

    context "and a confirmed order" do
      context "and valid input" do
        let(:carrier) { 'UPS' }
        let(:tracking_number) { '1Z12345E0205271688' }

        before do
          params[:shipment] = {carrier: carrier, tracking_number: tracking_number}
          post "/v1/orders/#{order.reference_number}/shipment", params
        end
        subject { response }

        its(:status) { should == 201 }
        its(:headers) { subject['Location'].should be }
        its(:body) { should be_empty }
      end

      context "and invalid input" do
        before { post "/v1/orders/#{order.reference_number}/shipment", params }
        subject { response }

        its(:status) { should == 400 }
        its(:json) { subject[:invalid_fields].should be }
      end
    end

    context "and an unconfirmed order" do
      let(:order) { FactoryGirl.create(:shipped_order, listing: listing) }

      before { post "/v1/orders/#{order.reference_number}/shipment", params }
      subject { response }

      its(:status) { should == 400 }
      its(:json) { subject[:message].should =~ /invalid state transition/i }
    end
  end

  context 'with invalid credentials' do
    before { post "/v1/orders/#{order.reference_number}/shipment" }
    subject { response }

    its(:status) { should == 401 }
    its(:json) { subject[:error].should == 'invalid_token' }
  end
end
