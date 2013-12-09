require 'spec_helper'

describe Users::AfterConnectionJob do
  subject { Users::AfterConnectionJob }

  let(:user) { stub_user 'Johnny Halliday' }

  describe "#import_profile_photo" do
    it 'syncs the profile photo' do
      user.expects(:async_set_profile_photo_from_network)
      subject.import_profile_photo(user)
    end
  end
end
