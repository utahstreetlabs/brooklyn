require 'spec_helper'

describe InvitesSent do
  describe '#directed_invites' do
    let(:fb_invitee_1) { stub_user 'Alex Lifeson', person: stub_person('fb1', id: 123) }
    let(:fb_invitee_profile_1) do
      stub_network_profile 'facebook-invitee-profile-1', :facebook, id: 'a', person_id: fb_invitee_1.person_id
    end
    let(:fb_invitee_profile_2) { stub_network_profile 'facebook-invitee-profile-2', :facebook, id: 'b', person_id: 567 }
    let(:fb_profile) do
      stub_network_profile 'facebook-profile', :facebook, inviting: [fb_invitee_profile_1, fb_invitee_profile_2]
    end
    let(:tw_invitee_profile_1) { stub_network_profile 'twitter-invitee-profile-1', :twitter, id: 'c', person_id: 423 }
    let(:tw_invitee_2) { stub_user 'Geddy Lee', person: stub_person('tw2', id: 456) }
    let(:tw_invitee_profile_2) do
      stub_network_profile 'twitter-invitee-profile-2', :twitter, id: 'd', person_id: tw_invitee_2.person_id
    end
    let(:tw_profile) do
      stub_network_profile 'twitter-profile', :twitter, inviting: [tw_invitee_profile_1, tw_invitee_profile_2]
    end
    let(:direct_invitees) { [fb_invitee_1, tw_invitee_2] }
    let(:direct_invitee_profiles) do
      [fb_invitee_profile_1, fb_invitee_profile_2, tw_invitee_profile_1, tw_invitee_profile_2]
    end
    let(:user) do
      u = stub_user 'Neil Peart', direct_invitees: direct_invitees, direct_invitee_profiles: direct_invitee_profiles
      u.stubs(:direct_inviter_profile).with(fb_invitee_profile_1).returns(fb_profile)
      u.stubs(:direct_inviter_profile).with(fb_invitee_profile_2).returns(fb_profile)
      u.stubs(:direct_inviter_profile).with(tw_invitee_profile_1).returns(tw_profile)
      u.stubs(:direct_inviter_profile).with(tw_invitee_profile_2).returns(tw_profile)
      u
    end

    it 'returns an InvitePresenter for each directly invited profile' do
      presenters = InvitesSent.directed_invites(user)
      presenters.should have(user.direct_invitee_profiles.size).presenters
      presenters[0].inviter_profile.should == fb_profile
      presenters[0].invitee.should == fb_invitee_1
      presenters[0].invitee_profile.should == fb_invitee_profile_1
      presenters[1].inviter_profile.should == fb_profile
      presenters[1].invitee.should be_nil
      presenters[1].invitee_profile.should == fb_invitee_profile_2
      presenters[2].inviter_profile.should == tw_profile
      presenters[2].invitee.should be_nil
      presenters[2].invitee_profile.should == tw_invitee_profile_1
      presenters[3].inviter_profile.should == tw_profile
      presenters[3].invitee.should == tw_invitee_2
      presenters[3].invitee_profile.should == tw_invitee_profile_2
    end

    describe '#undirected_invites' do
      let(:inviter_1) { stub_user 'Ginger Baker' }
      let(:inviter_2) { stub_user 'Jack Bruce' }
      let(:invitees) { [inviter_1, inviter_2] }
      let(:user) { stub_user 'Steve Winwood', untargeted_invitees: invitees }

      it 'returns an InvitePresenter for each accepter of an untargeted invite' do
        presenters = InvitesSent.undirected_invites(user)
        presenters.should have(invitees.size).presenters
        presenters[0].invitee.should == inviter_1
        presenters[1].invitee.should == inviter_2
      end
    end
  end
end
