require 'spec_helper'

describe Users::SyncPhotoJob do
  let(:user) { stub_user 'Max Headroom' }
  let(:network) { :facebook }

  before do
    User.stubs(:find).with(user.id).returns(user)
  end

  it 'downloads and sets the profile photo' do
    user.expects(:set_profile_photo_from_network).with(network)
    user.expects(:save!)
    Users::SyncPhotoJob.work(user.id, network)
  end
end
