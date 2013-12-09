require 'spec_helper'

describe Credits::AfterCreatedJob do
  subject { Credits::AfterCreatedJob }

  let(:credit) { stub('credit', id: 123, amount: 100, user: stub('user')) }

  describe '#send_inviter_credit_granted_email' do
    context 'when inviter credit' do
      let(:invitee) { stub_user 'Robin' }
      let(:inviter) { stub_user 'Batman' }
      let(:trigger) { Lagunitas::InviterCreditTrigger.new(invitee_id: invitee.id) }

      before do
        credit.stubs(:trigger).returns(trigger)
        credit.stubs(:user_id).returns(inviter.id)
        User.stubs(:find_by_id).with(invitee.id).returns(invitee)
        User.stubs(:find_by_id).with(inviter.id).returns(inviter)
      end

      it 'sends email' do
        subject.expects(:send_email).with(:invitee_purchase_credit, inviter, invitee.to_job_hash)
        subject.send_inviter_credit_granted_email(credit)
      end
    end

    context 'when not inviter credit' do
      let(:trigger) { Lagunitas::SignupCreditTrigger.new }
      before { credit.stubs(:trigger).returns(:trigger) }

      it 'does not send email' do
        subject.expects(:send_email).never
        subject.send_inviter_credit_granted_email(credit)
      end
    end
  end

  describe '#schedule_credit_reminder_1' do
    context 'when the credit period is less than halfway elapsed' do
      it 'schedules the reminder job' do
        credit.stubs(:validity_duration).returns((Credit.min_days_halfway_reminder * 2).days)
        SendCreditReminderOne.expects(:enqueue_at)
        subject.schedule_credit_reminder_1(credit)
      end
    end

    context 'when the credit period is more than halfway elapsed' do
      it 'does not schedule the reminder job' do
        credit.stubs(:validity_duration).returns((Credit.min_days_halfway_reminder / 2).days)
        SendCreditReminderOne.expects(:enqueue_at).never
        subject.schedule_credit_reminder_1(credit)
      end
    end
  end

  describe '#update_mixpanel' do
    it "should increment its user's credit_earned property in mixpanel" do
      credit.user.expects(:mixpanel_increment!).with(credits_earned: credit.amount)
      Credits::AfterCreatedJob.update_mixpanel(credit)
    end
  end
end
