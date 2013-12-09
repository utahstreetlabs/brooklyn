require 'spec_helper'

describe InviteAcceptances::AfterCreationJob do
  subject { InviteAcceptances::AfterCreationJob }

  describe '#update_mixpanel' do

    context 'for a Facebook U2U invite' do
      let(:u2u) { FactoryGirl.create(:facebook_u2u_invite) }
      let(:sender) { u2u.request.user }
      let(:invite_acceptance) do
        FactoryGirl.create(:invite_acceptance, inviter_id: sender.id, facebook_u2u_invite: u2u)
      end
      let(:recipient) { invite_acceptance.user }

      it 'should increment mixpanel count and track usage' do
        sender.expects(:mixpanel_increment!).with(:invites_accepted)
        subject.expects(:track_usage).
          with(:invite_accepted,
               user: recipient,
               source: u2u.source,
               share_channel: 'facebook_request',
               sender: sender.slug,
               recipient: u2u.fb_user_id)
        subject.update_mixpanel(invite_acceptance)
      end
    end

    context 'for any other kind of invite' do
      let(:inviter) { FactoryGirl.create(:registered_user) }
      let(:invite_acceptance) { FactoryGirl.create(:invite_acceptance, inviter_id: inviter.id) }
      let(:invitee) { invite_acceptance.user }

      before do
        # stubs Rubicon access
        invitee.stubs(:accepted_inviter).returns(inviter)
      end

      it 'should increment mixpanel count and track usage' do
        inviter.expects(:mixpanel_increment!).with(:invites_accepted)
        subject.expects(:track_usage).
          with(:invite_accepted,
               user: invite_acceptance.user,
               inviter: inviter.slug,
               invitee: invitee.slug)
        subject.update_mixpanel(invite_acceptance)
      end
    end
  end
end
