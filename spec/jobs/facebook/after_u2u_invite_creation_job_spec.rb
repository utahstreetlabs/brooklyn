require 'spec_helper'

describe Facebook::AfterU2uInviteCreationJob do
  subject { Facebook::AfterU2uInviteCreationJob }
  let(:u2u) { FactoryGirl.create(:facebook_u2u_invite) }

  describe '#update_mixpanel' do
    it "tracks usage" do
      subject.expects(:track_usage).
        with(:invite_sent,
             user: u2u.request.user,
             source: u2u.source,
             share_channel: 'facebook_request',
             sender: u2u.request.user.slug,
             recipient: u2u.fb_user_id)
      subject.update_mixpanel(u2u)
    end
  end
end
