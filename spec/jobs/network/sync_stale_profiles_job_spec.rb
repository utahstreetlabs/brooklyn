require 'spec_helper.rb'

describe Network::SyncStaleProfilesJob do
  let(:seconds) { 100 }
  let(:user) { stub_user 'Eric Clapton' }

  before do
    User.stubs(:each_unsynced_after_deleting_inactive).with(seconds).yields(user)
  end

  context "unconnected profile" do
    before do
      user.person.network_profiles.each_pair do |network, profile|
        profile.stubs(:connected?).returns(false)
      end
    end

    it "is skipped" do
      Network::SyncStaleProfilesJob.perform(seconds).should == 1
    end
  end

  context "connected profile" do
    before do
      user.person.network_profiles.each_pair do |network, profile|
        profile.stubs(:connected?).returns(true)
      end
    end

    context "for network other than facebook that does not implement attr sync" do
      before do
        user.person.network_profiles.each_pair do |network, profile|
          if network == :facebook
            profile.expects(:async_sync_attrs).never
          else
            profile.expects(:async_sync_attrs).raises(NotImplementedError)
          end
        end
      end

      it "is skipped" do
        Network::SyncStaleProfilesJob.perform(seconds).should == 1
      end
    end

    context "for network other than facebook that implements attr sync" do
      before do
        user.person.network_profiles.each_pair do |network, profile|
          if network == :facebook
            profile.expects(:async_sync_attrs).never
          else
            profile.expects(:async_sync_attrs)
          end
        end
      end

      it "syncs the profile's attrs" do
        Network::SyncStaleProfilesJob.perform(seconds).should == 1
      end
    end
  end

end
