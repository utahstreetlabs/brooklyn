require 'spec_helper'

describe Brooklyn::Carrier do
  context "when fetching carrier objects" do
    let(:carrier_names) { [:ups, :usps] }
    subject { Brooklyn::Carrier.available }

    before do
      Brooklyn::Application.config.shipping.stubs(:active).returns(carrier_names)
    end

    context "and listing available carriers" do
      it { should have(2).carriers }
    end

    context "and getting the ups carrier by key" do
      let(:carrier) { Brooklyn::Carrier.for_key(:ups) }
      subject { carrier }
      its(:key) { should == :ups }
      its(:name) { should == 'UPS' }

      context "and accessing the remote client" do
        let(:client) { stub_everything('ups client') }
        subject { carrier.client }
        before do
          ActiveMerchant::Shipping::UPS.expects(:new).with(
            login: Brooklyn::Application.config.shipping.ups.credentials.login,
            password: Brooklyn::Application.config.shipping.ups.credentials.password,
            key: Brooklyn::Application.config.shipping.ups.credentials.key).returns(client)
        end

        it { should == client }
      end
    end

    context "and getting the usps carrier by key" do
      let(:carrier) { Brooklyn::Carrier.for_key(:usps) }
      subject { carrier }
      its(:key) { should == :usps }
      its(:name) { should == 'USPS' }

      context "and accessing the remote client" do
        let(:client) { stub_everything('usps client') }
        subject { carrier.client }
        before do
          ActiveMerchant::Shipping::USPS.expects(:new).with(
            login: Brooklyn::Application.config.shipping.usps.credentials.login,
            password: Brooklyn::Application.config.shipping.usps.credentials.password).returns(client)
        end

        it { should == client }
      end
    end
  end
end

describe Brooklyn::Carrier::Usps do
  describe '#clean_tracking_number' do
    subject { Brooklyn::Carrier.for_key(:usps).clean_tracking_number(tracking_number) }
    context "with a 30 character number" do
      let(:tracking_number) { "420941079101150134711775100763" }
      it { should == "9101150134711775100763" }
    end

    context "with whitespace in the tracking number" do
      let(:tracking_number) { "  910\t1150  13471 17751 00763 " }
      it { should == "9101150134711775100763" }
    end
  end
end
