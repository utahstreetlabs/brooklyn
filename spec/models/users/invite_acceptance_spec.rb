require 'spec_helper'

describe Users::InviteAcceptance do
  subject { FactoryGirl.create(:connected_user) }

  shared_examples 'asserts acceptance state' do
    (User.state_machine(:state).states.keys - [:connected]).each do |state|
      context "when subject is in #{state} state " do
        subject { FactoryGirl.create("#{state}_user".to_sym) }
        it 'should raise' do
          expect { subject.accept_invite!('deadbeef') }.
            to raise_exception(Users::InviteAcceptance::InvalidInviteAcceptanceState)
        end
      end
    end

    context "when subject has already accepted an invite" do
      let(:existing_code) { 'phatpipe' }
      let!(:acceptance) { subject.create_invite_acceptance!(invite_uuid: existing_code, inviter_id: 123) }
      it 'should raise' do
        expect { subject.accept_invite!('deadbeef') }.to raise_exception(Users::InviteAcceptance::InviteAcceptanceFound)
      end
    end
  end

  describe "#accept_invite!" do
    it_behaves_like 'asserts acceptance state'

    context 'subject can accept an invite' do
      let(:code) { 'deadbeef' }

      context "and the identified invite exists" do
        let(:invite) { stub('invite', uuid: code, inviter_id: 123) }
        before { Invite.stubs(:find_by_uuid).with(code).returns(invite) }

        context "and the inviter exists" do
          before do
            invite.stubs(:inviter).returns(stub('inviter'))
            InviteAcceptances::AfterCreationJob.expects(:enqueue)
            subject.accept_invite!(code)
          end
          its(:invite_acceptance) { subject.invite_uuid.should == code }
          its(:invite_acceptance) { subject.inviter_id.should == invite.inviter_id }
        end

        context "and the inviter does not exist" do
          before { invite.stubs(:inviter).returns(nil) }
          it 'should raise' do
            expect { subject.accept_invite!(code) }.to raise_exception(Users::InviteAcceptance::InviterNotFound)
          end
        end
      end

      context "and the identified invite does not exist" do
        before { Invite.stubs(:find_by_uuid).with(code).returns(nil) }
        it 'should raise' do
          expect { subject.accept_invite!(code) }.to raise_exception(Users::InviteAcceptance::InviteNotFound)
        end
      end
    end
  end

  describe '#accept_pending_facebook_u2u_invite' do
    it_behaves_like 'asserts acceptance state'

    context 'when subject can accept an invite' do
      context 'and has a Facebook profile' do
        let(:profile) { stub('profile') }
        before { subject.stubs(:for_network).with(Network::Facebook).returns(profile) }

        context 'and has pending U2U invite requests' do
          let(:u2us) { FactoryGirl.create_list(:facebook_u2u_invite, 2) }
          before { profile.stubs(:pending_u2u_invites).returns(u2us) }

          context "and a U2U's invite exists" do
            let(:invite) { stub('invite', uuid: u2us.first.invite_code) }
            before { Invite.stubs(:find_from_u2us).returns([invite, u2us.first]) }

            context "and the invite's inviter exists" do
              let(:inviter) { stub('inviter', id: 4567) }
              before do
                invite.stubs(:inviter).returns(inviter)
                invite.stubs(:inviter_id).returns(inviter.id)
              end

              context 'and the transaction commits' do
                it 'accepts the invite, completes the U2Us and deletes their app requests' do
                  u2us.each do |u2u|
                    u2u.expects(:async_delete_app_request)
                  end
                  acceptance = subject.accept_pending_facebook_u2u_invite!
                  expect(acceptance).to be_a(InviteAcceptance)
                  expect(acceptance.invite_uuid).to eq(invite.uuid)
                  expect(acceptance.inviter_id).to eq(inviter.id)
                  expect(acceptance.facebook_u2u_invite).to eq(u2us.first)
                  u2us.each do |u2u|
                    expect(u2u.complete?).to be_true
                    expect(u2u.user).to eq(subject)
                  end
                end
              end

              context 'but the transaction rolls back' do
                before { u2us.last.expects(:complete!).raises("Boom!") }

                it 'does not accept the invite, complete the U2Us or delete their app requests' do
                  u2us.each do |u2u|
                    u2u.expects(:async_delete_app_request).never
                  end
                  expect { subject.accept_pending_facebook_u2u_invite! }.to raise_exception
                  subject.reload
                  expect(subject.accepted_invite?).to be_false
                  u2us.each do |u2u|
                    u2u.reload
                    expect(u2u.complete?).to be_false
                    expect(u2u.user).to be_nil
                  end
                end
              end
            end

            context "but the invite's inviter does not exist" do
              before { invite.stubs(:inviter).returns(nil) }

              it 'raises InviterNotFound' do
                expect { subject.accept_pending_facebook_u2u_invite! }.
                  to raise_exception(Users::InviteAcceptance::InviterNotFound)
                expect(subject.accepted_invite?).to be_false
              end
            end
          end

          context "but none of the U2Us' invites exist" do
            before { Invite.stubs(:find_from_u2us).returns(nil) }

            it 'raises InviteNotFound' do
              expect { subject.accept_pending_facebook_u2u_invite! }.
                to raise_exception(Users::InviteAcceptance::InviteNotFound)
              expect(subject.accepted_invite?).to be_false
            end
          end
        end

        context 'but no pending U2U invites' do
          before { profile.stubs(:pending_u2u_invites).returns([]) }

          it 'does nothing and returns nil' do
            expect(subject.accept_pending_facebook_u2u_invite!).to be_nil
          end
        end
      end

      context 'but does not have a Facebook profile' do
        before { subject.stubs(:for_network).with(Network::Facebook).returns(nil) }

        it 'does nothing and returns nil' do
          expect(subject.accept_pending_facebook_u2u_invite!).to be_nil
        end
      end
    end
  end

  describe '#accepted_invite?' do
    context "and subject has not accepted an invite" do
      its(:accepted_invite?) { should be_false }
    end

    context "and subject has accepted an invite" do
      before { subject.create_invite_acceptance!(invite_uuid: 'deadbeef') }
      its(:accepted_invite?) { should be_true }
    end
  end

  describe '#accepted_invite' do
    let(:invite) { mock('invite') }

    context "and subject has not accepted an invite" do
      its(:accepted_invite) { should be_nil }
    end

    context "and subject has accepted an invite" do
      before do
        ia = subject.create_invite_acceptance!(invite_uuid: 'deadbeef')
        ia.stubs(:invite).returns(invite)
      end
      its(:accepted_invite) { should == invite }
    end
  end

  describe '#accepted_inviter' do
    let(:inviter) { stub_user 'Edward Teach' }

    context "when subject has not accepted an invite" do
      before do
        subject.stubs(:accepted_untargeted_invite?).returns(false)
        subject.stubs(:accepted_targeted_invite?).returns(false)
      end
      its(:accepted_inviter) { should be_nil }
    end

    context "and subject has accepted an untargeted invite" do
      before do
        subject.stubs(:accepted_untargeted_invite?).returns(true)
        subject.stubs(:accepted_targeted_invite?).returns(false)
        subject.stubs(:indirectly_invited_by).returns(inviter)
      end
      its(:accepted_inviter) { should == inviter }
    end

    context "and subject has accepted a targeted invite" do
      before do
        subject.stubs(:accepted_untargeted_invite?).returns(false)
        subject.stubs(:accepted_targeted_invite?).returns(true)
        subject.stubs(:directly_invited_by).returns(inviter)
      end
      its(:accepted_inviter) { should == inviter }
    end
  end

  describe '#directly_invited_profile' do
    let(:invite) { stub('invite', invitee_id: 'cafebebe') }
    let(:profile) { stub('profile', id: invite.invitee_id) }

    it 'returns the profile, if the user accepted a targeted invite' do
      invite.stubs(:targeted?).returns(true)
      subject.stubs(:accepted_invite).returns(invite)
      Rubicon::Profile.expects(:find).with(invite.invitee_id).returns(profile)
      subject.directly_invited_profile.decorated.should == profile
    end

    it 'does not return a profile if the user did not accept an invite' do
      subject.stubs(:accepted_invite).returns(nil)
      Rubicon::Profile.expects(:find).never
      subject.directly_invited_profile.should be_nil
    end

    it 'does not return a profile if the user accepted an untargeted invite' do
      invite.stubs(:targeted?).returns(false)
      subject.stubs(:accepted_invite).returns(invite)
      Rubicon::Profile.expects(:find).never
      subject.directly_invited_profile.should be_nil
    end
  end

  describe '#directly_invited_by' do
    let(:inviter) { stub_user 'Matt Damon' }
    let(:invite) { stub('invite', inviter_id: inviter.id) }
    let(:profile) { stub('profile', person_id: invite.inviter_id) }

    it 'returns the inviter, if the user accepted a targeted invite' do
      invite.stubs(:targeted?).returns(true)
      subject.stubs(:accepted_invite).returns(invite)
      User.expects(:find_by_id).with(inviter.id).returns(inviter)
      subject.directly_invited_by.should == inviter
    end

    it 'does not return a user if the user did not accept an invite' do
      subject.stubs(:accepted_invite).returns(nil)
      User.expects(:find_by_id).never
      subject.directly_invited_by.should be_nil
    end

    it 'does not return a user if the user accepted an untargeted invite' do
      invite.stubs(:targeted?).returns(false)
      subject.stubs(:accepted_invite).returns(invite)
      User.expects(:find_by_id).never
      subject.directly_invited_by.should be_nil
    end
  end

  describe "#directly_invited_by?" do
    let(:candidate) { stub_user('Bryan Ferry') }

    it "returns true when the user was invited by the candidate" do
      subject.expects(:directly_invited_by).returns(candidate)
      subject.directly_invited_by?(candidate).should be_true
    end

    it "returns false when the user was not invited by the candidate" do
      subject.expects(:directly_invited_by).returns(nil)
      subject.directly_invited_by?(candidate).should be_false
    end
  end

  describe "#inviters" do
    subject { FactoryGirl.create(:registered_user) }

    let(:untargeted_inviter) { FactoryGirl.create(:registered_user) }
    let(:untargeted_invite) { stub('untargeted-invite', person_id: untargeted_inviter.person_id) }
    let(:targeted_inviter) { FactoryGirl.create(:registered_user) }
    let(:targeted_profile) { stub_network_profile 'targeted-profile', :twitter, inviters: [targeted_inviter] }

    before do
      subject.stubs(:accepted_untargeted_invite?).returns(true)
      subject.stubs(:accepted_invite).returns(untargeted_invite)
      subject.stubs(:map_connected_profiles).yields(targeted_profile).
        returns(targeted_profile.inviters.map(&:person_id))
    end

    its(:inviters) { should include(untargeted_inviter) }
    its(:inviters) { should include(targeted_inviter) }
  end

  describe "#direct_invite_count" do
    it "finds the total count of profiles it has invited" do
      twitter1 = stub('profile', inviting_count: 2)
      twitter2 = stub('profile', inviting_count: 2)
      facebook = stub('profile', inviting_count: 1)
      subject.person.stubs(:network_profiles).returns(twitter: [twitter1, twitter2], facebook: facebook)
      subject.direct_invite_count.should == 5
    end
  end

  describe 'direct invitees' do
    subject { FactoryGirl.create(:registered_user) }

    let(:fb_invitee_1) { FactoryGirl.create(:registered_user) }
    let(:fb_invitee_profile_1) do
      stub_network_profile 'facebook-invitee-profile-1', :facebook, id: 'a', person_id: fb_invitee_1.person_id
    end
    let(:fb_invitee_profile_2) { stub_network_profile 'facebook-invitee-profile-2', :facebook, id: 'b', person_id: 567 }
    let(:fb_profile) do
      stub_network_profile 'facebook-profile', :facebook, inviting: [fb_invitee_profile_1, fb_invitee_profile_2]
    end
    let(:tw_invitee_profile_1) { stub_network_profile 'twitter-invitee-profile-1', :twitter, id: 'c', person_id: 423 }
    let(:tw_invitee_2) { FactoryGirl.create(:registered_user) }
    let(:tw_invitee_profile_2) do
      stub_network_profile 'twitter-invitee-profile-2', :twitter, id: 'd', person_id: tw_invitee_2.person_id
    end
    let(:tw_profile) do
      stub_network_profile 'twitter-profile', :twitter, inviting: [tw_invitee_profile_1, tw_invitee_profile_2]
    end
    let(:connected_profiles) { [fb_profile, tw_profile] }
    let(:invitee_profiles) { [fb_invitee_profile_1, fb_invitee_profile_2, tw_invitee_profile_1, tw_invitee_profile_2] }
    let(:invitees) { [fb_invitee_1, tw_invitee_2] }

    before do
      subject.person.stubs(:connected_profiles).returns(connected_profiles)
    end

    its(:direct_invitee_profiles) { should == invitee_profiles }
    its(:direct_invitees) { should == invitees }

    context 'with populated direct inviter profile cache' do
      before { subject.direct_invitee_profiles }
      it { subject.direct_inviter_profile(fb_invitee_profile_1).should == fb_profile }
      it { subject.direct_inviter_profile(tw_invitee_profile_1).should == tw_profile }
    end
  end
end
