require "spec_helper"

describe GrantInviteeCredit do
  let(:invitee) { stub_user('Red Sonja') }
  let(:type) { :invitee }

  it "grants credit if eligible" do
    User.expects(:find).with(invitee.id).returns(invitee)
    Credit.expects(:grant_if_eligible!).with(invitee, type)
    GrantInviteeCredit.perform(invitee.id)
  end

  it "does not propagate an exception" do
    User.expects(:find).with(invitee.id).raises(ActiveRecord::RecordNotFound)
    Credit.expects(:grant_if_eligible!).never
    expect { GrantInviteeCredit.perform(invitee.id) }.not_to raise_error
  end
end
