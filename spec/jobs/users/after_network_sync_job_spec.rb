require 'spec_helper'

describe Users::AfterNetworkSyncJob do
  subject { Users::AfterNetworkSyncJob }

  let(:user) { stub_user 'John Woo' }
  let(:person) { user.person }
  let(:network) { 'facebook' }
  let(:fb_profile) { stub_network_profile('John Woo', :facebook) }

  describe "#work" do
    it "should update mixpanel with network profile information" do
      Person.expects(:find).with(person.id).returns(person)
      person.expects(:for_network).with(network).returns(fb_profile)
      user.expects(:mixpanel_set!).with("#{network}_follows" => fb_profile.api_follows_count)
      Users::AfterNetworkSyncJob.work(person.id, network)
    end
  end
end

