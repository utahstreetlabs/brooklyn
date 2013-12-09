require 'spec_helper'

describe OrderHooks do
  describe '#post_headers' do
    subject { OrderHooks.post_headers('xml', 'abc', 'CREATED') }

    it 'sets Content-type in post headers' do
      subject[:'Content-Type'].should  == 'application/xml; charset=utf-8'
    end

    it 'sets Accept in post headers' do
      subject[:'Accept'].should  == 'application/xml; charset=utf-8'
    end

    it 'sets Authorization in post headers' do
      subject[:'Authorization'].should  == "Basic #{ActiveSupport::Base64.encode64s('abc:')}"
    end

    it 'sets the X-Notification-Type header' do
      subject[:'X-Notification-Type'].should == 'CREATED'
    end
  end

  describe '#fire' do
    let(:api_config) { stub('api_config', callback_url: 'test', format: 'json', token: 'a') }
    let(:order) { FactoryGirl.create(:confirmed_order) }

    before do
      order.listing.seller.expects(:api_config).returns(api_config)
      order.expects(:api_hash).returns('a')
      order.expects(:api_callback?).returns(true)
    end

    it 'should notify Airbrake if unsucessful' do
      Typhoeus::Request.expects(:post).returns(stub('response', code: 400, body: 'test'))
      Airbrake.expects(:notify)
      OrderHooks.fire(order, :created)
    end

    it 'should not notify Airbrake if sucessful' do
      Typhoeus::Request.expects(:post).returns(stub('response', code: 200))
      Airbrake.expects(:notify).never
      OrderHooks.fire(order, :created)
    end
  end
end
