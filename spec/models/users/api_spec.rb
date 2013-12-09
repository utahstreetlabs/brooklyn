require 'spec_helper'

describe Users::Api do
  describe '#find_or_create_api_config' do
    subject { FactoryGirl.create(:registered_user) }

    let(:api_config) { FactoryGirl.create(:api_config, user: subject, token: 'deadbeef') }

    it "returns existing api config" do
      subject.expects(:api_config).returns(api_config)
      subject.find_or_create_api_config.should == api_config
    end

    it "creates a new api config" do
      subject.expects(:api_config).returns(nil)
      subject.expects(:create_api_config!).returns(api_config)
      subject.find_or_create_api_config.should == api_config
    end

    it "raises an exception if api config can't be created" do
      subject.expects(:api_config).returns(nil)
      subject.expects(:create_api_config!).raises(Exception)
      expect { subject.find_or_create_api_config }.to raise_exception(Exception)
    end
  end
end
