require 'spec_helper'

describe Facebook::DirectShareInviteJob do
  class Person
  end

  let(:inviter) { stub_person('jimmy-page') }
  let(:invitee) { stub_network_profile('john-bonham', :facebook) }
  let(:params) { {'foo' => 'bar'} }

  it "sends an invite via Facebook direct share" do
    Person.expects(:find).with(inviter.id).returns(inviter)
    Invites::FacebookDirectShareContext.expects(:send_direct_share).with(inviter, invitee.id, params.symbolize_keys)
    Facebook::DirectShareInviteJob.perform(inviter.id, invitee.id, params)
  end

  it "does not propagate an exception" do
    Person.expects(:find).with(inviter.id).raises("Boom!")
    Invites::FacebookDirectShareContext.expects(:send_direct_share).never
    expect { Facebook::DirectShareInviteJob.perform(inviter.id, invitee.id, params) }.not_to raise_error
  end
end
