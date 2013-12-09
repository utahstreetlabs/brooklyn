require 'spec_helper'

describe Invite do
  describe '.inviter' do
    let(:inviter) { stub_user 'Joey Ramone' }

    subject { Invite.new(invite) }

    context "for an untargeted invite" do
      let(:invite) { Rubicon::UntargetedInvite.new(_id: 'deadbeef', person_id: inviter.person.id) }

      context "when the inviter exists" do
        before { User.stubs(:find_by_person_id).with(inviter.person.id).returns(inviter) }
        its(:inviter) { should == inviter }
      end

      context "when the inviter does not exist" do
        before { User.stubs(:find_by_person_id).with(inviter.person.id).returns(nil) }
        its(:inviter) { should be_nil }
      end
    end

    context "for a targeted invite" do
      let(:inviter_profile) { stub 'inviter-profile', id: 'cafebebe', person_id: inviter.person.id }
      let(:invite) { Rubicon::Invite.new(_id: 'deadbeef', inviter_id: inviter_profile.id) }

      context "when the inviter's profile exists" do
        before { Rubicon::Profile.stubs(:find).with(inviter_profile.id).returns(inviter_profile) }

        context "when the inviter exists" do
          before { User.stubs(:find_by_person_id).with(inviter.person.id).returns(inviter) }
          its(:inviter) { should == inviter }
        end

        context "when the inviter does not exist" do
          before { User.stubs(:find_by_person_id).with(inviter_profile.person_id).returns(nil) }
          its(:inviter) { should be_nil }
        end
      end

      context "when the inviter's profile does not exist" do
        before { Rubicon::Profile.stubs(:find).with(inviter_profile.id).returns(nil) }
        its(:inviter) { should be_nil }
      end
    end
  end

  describe '#find_from_u2us' do
    it 'returns the first found invite' do
      invite = stub('invite')
      u2us = FactoryGirl.create_list(:facebook_u2u_invite, 2)
      Invite.stubs(:find_by_uuid).with(u2us.first.invite_code).returns(nil)
      Invite.stubs(:find_by_uuid).with(u2us.second.invite_code).returns(invite)
      Invite.find_from_u2us(u2us).should == [invite, u2us.second]
    end

    it 'returns nil if no invites are found' do
      u2us = FactoryGirl.create_list(:facebook_u2u_invite, 2)
      Invite.stubs(:find_by_uuid).returns(nil)
      Invite.find_from_u2us(u2us).should be_nil
    end
  end
end
