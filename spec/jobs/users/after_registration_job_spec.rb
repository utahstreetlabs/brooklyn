require 'spec_helper'

describe Users::AfterRegistrationJob do
  subject { Users::AfterRegistrationJob }

  let(:inviters) do
    [stub_user('Claude Francois', allow_email?: false),
     stub_user('Henri Salvador', allow_email?: true)]
  end
  let(:network_followers) do
    [inviters.first,
     stub_user('Valerie Lagrange', allow_email?: false),
     stub_user('Eric Charden', allow_email?: true)]
  end
  let(:user) { stub_user 'Serge Gainsbourg', inviters: inviters, all_registered_network_followers: network_followers }

  describe '#grant_invitee_credit' do
    it 'enqueues GrantInviteeCredit when the user was invited' do
      user.stubs(:accepted_invite?).returns(true)
      GrantInviteeCredit.expects(:enqueue).with(user.id)
      subject.grant_invitee_credit(user)
    end

    it 'does not enqueue GrantInviteeCredit when the user was not invited' do
      user.stubs(:accepted_invite?).returns(false)
      GrantInviteeCredit.expects(:enqueue).never
      subject.grant_invitee_credit(user)
    end
  end

  describe '#email_invite_accepted' do
    it 'sends :invite_accepted email to each inviter that allows that email' do
      subject.expects(:send_email).with(:invite_accepted, inviters.first, user.to_job_hash).never
      subject.expects(:send_email).with(:invite_accepted, inviters.second, user.to_job_hash)
      subject.email_invite_accepted(user)
    end
  end

  describe '#email_welcome_1' do
    it 'sends :welcome_1 email when directed to' do
      subject.expects(:send_email).with(:welcome_1, user)
      subject.email_welcome_1(user, send_welcome_emails: true)
    end

    it 'does not send :welcome_1 email when not directed to' do
      subject.expects(:send_email).never
      subject.email_welcome_1(user, send_welcome_emails: false)
    end
  end

  describe '#email_joined' do
    it 'sends :friend_joined email to each network follower who did not invite the user and allows the email' do
      subject.expects(:send_email).with(:friend_joined, user, network_followers.first.id).never
      subject.expects(:send_email).with(:friend_joined, user, network_followers.second.id).never
      subject.expects(:send_email).with(:friend_joined, user, network_followers.third.id)
      subject.email_joined(user)
    end
  end

  describe '#schedule_draft_listing_reminder' do
    it 'schedules DraftListingReminder job' do
      Time.freeze do
        DraftListingReminder.expects(:enqueue_at).with(1.day.from_now, user.id)
        subject.schedule_draft_listing_reminder(user)
      end
    end
  end

  describe '#update_mixpanel' do
    it 'should mark each inviter as an inviter' do
      user.expects(:mixpanel_sync!)
      inviters.each do |u|
        u.expects(:mark_inviter!)
        u.expects(:mixpanel_sync!)
      end
      subject.update_mixpanel(user)
    end
  end
end
