require 'spec_helper'

describe Facebook::DeleteU2uInviteRequestJob do
  let(:u2u) { FactoryGirl.create(:facebook_u2u_invite) }

  it "deletes the associated app request" do
    FacebookU2uInvite.any_instance.expects(:delete_app_request!)
    Facebook::DeleteU2uInviteRequestJob.perform(u2u.id)
  end
end
