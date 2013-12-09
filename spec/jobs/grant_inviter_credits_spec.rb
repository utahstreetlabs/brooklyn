require "spec_helper"

describe GrantInviterCredits do
  subject { GrantInviterCredits }

  let(:invitee) { stub_user 'Robert Smith' }
  before { User.stubs(:find).with(invitee.id).returns(invitee) }

  context "when the user accepted an invite" do
    let(:inviter) { stub_user 'Patti Smith' }
    before { invitee.stubs(:accepted_inviter).returns(inviter) }

    it "should grant an inviter credit" do
      Credit.expects(:grant_if_eligible!).with(inviter, :inviter, has_entry(invitee_id: invitee.id))
      subject.perform(invitee.id)
    end
  end

  context 'when the user did not accept an invite' do
    before { invitee.stubs(:accepted_inviter).returns(nil) }

    it 'should not grant an inviter credit' do
      Credit.expects(:grant_if_eligible!).never
      subject.perform(invitee.id)
    end
  end
end
