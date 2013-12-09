require 'spec_helper'

describe Brooklyn::ShippingLabels::StampsService do
  let(:stamps) { stub('stamps') }
  subject { Brooklyn::ShippingLabels::StampsService.new(Brooklyn::Application.config.stamps) }
  before { subject.stubs(:stamps).returns(stamps) }

  describe '#generate!' do
    let(:params) do
      {
        local_tx_id: 'abcdef',
        shipping_option: :small_box,
        to: {
          full_name: 'Fred Flintstone',
          address1: '301 Cobblestone Way',
          address2: '',
          city: 'Bedrock',
          state: 'CA',
          zip_code: '99999'
        },
        from: {
          full_name: 'Barney Rubble',
          address1: '303 Cobblestone Way',
          address2: '',
          city: 'Bedrock',
          state: 'CA',
          zip_code: '99999'
        }
      }
    end

    context 'when the web method succeeds' do
      let(:stamp) do
        stub('stamp', tracking_number: '1Z12345E0205271688', url: 'http://usps.com/shipping-label',
             stamps_tx_id: 'c605aec1-322e-48d5-bf81-b0bb820f9c22')
      end
      before { stamps.stubs(:create!).returns(stamp) }

      it 'returns a label' do
        label = subject.generate!(params)
        label.tracking_number.should == stamp.tracking_number
        label.url.should == stamp.url
        label.tx_id.should == stamp.stamps_tx_id
      end
    end

    context 'when the web method fails' do
      let(:response) { stub('response', valid?: false, errors: []) }
      before { stamps.stubs(:create!).returns(response) }

      context "due to an invalid to address" do
        before { response.errors << 'Invalid Destination Address' }

        it 'raises InvalidToAddress' do
          expect { subject.generate!(params) }.to raise_error(Brooklyn::ShippingLabels::InvalidToAddress)
        end
      end

      context "due to an invalid to zip code" do
        before { response.errors << 'Invalid Destination Zip Code' }

        it 'raises InvalidToZipCode' do
          expect { subject.generate!(params) }.to raise_error(Brooklyn::ShippingLabels::StampsService::InvalidToZipCode)
        end
      end

      context 'due to any other condition' do
        before { response.errors << 'Something went horribly awray' }

        it 'raises ApiException' do
          expect { subject.generate!(params) }.to raise_error(Brooklyn::ShippingLabels::StampsService::ApiException)
        end
      end
    end
  end

  describe '#download' do
    context "when the download succeeds" do
      it "returns a tempfile with the contents of the downloaded resource" do
        url = 'http://example.com/shipping-label'
        content = "this is the label"
        subject.http.stubs(:get_content).with(url).yields(content)
        dest = subject.download(url)
        File.open(dest.path) do |io|
          io.read.should == content
        end
      end
    end
  end

  describe '#shipped?' do
    let(:tx_id) { 'deadbeef' }
    context 'when the web method succeeds' do
      let(:en) { stub('en', tracking_event_type: 'ElectronicNotification') }
      let(:sh) { stub('sh', tracking_event_type: 'Shipped') }
      before { stamps.stubs(:track).with(tx_id).returns(track) }

      context "and a tracking event is found" do
        let(:track) { stub('track', tracking_events: stub('te', tracking_event: [en, sh])) }

        it 'returns true' do
          subject.shipped?(tx_id).should be_true
        end
      end

      context "and no tracking events are found" do
        let(:track) { stub('track', tracking_events: stub('te', tracking_event: [])) }

        it 'returns false' do
          subject.shipped?(tx_id).should be_false
        end
      end

      context "and no relevant tracking events are found in the production environment" do
        let(:track) { stub('track', tracking_events: stub('te', tracking_event: en)) }
        before { Brooklyn::Application.config.stamps.use_test_environment = false}

        it 'returns false' do
          subject.shipped?(tx_id).should be_false
        end
      end
    end

    context 'when the web method fails' do
      let(:response) { stub('response', valid?: false, errors: ['Bogus request brah']) }
      before { stamps.stubs(:track).with(tx_id).returns(response) }

      it 'raises an ApiException' do
        expect { subject.shipped?(tx_id) }.to raise_error(Brooklyn::ShippingLabels::StampsService::ApiException)
      end
    end
  end
end
