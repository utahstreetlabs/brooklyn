require 'spec_helper'

describe InvitesController do
  describe "#show" do
    let(:invite_id) { 'slingshot' }
    let(:invite) { stub('invite', id: invite_id, inviter_id: 'cafebebe', invitee_id: 'deadbeef') }

    context 'with a logged-out user' do
      it 'succeeds for an untargeted invite' do
        Rubicon::UntargetedInvite.expects(:find).with(invite_id).returns(invite)
        Rubicon::Invite.expects(:find).never
        get :show, id: invite_id
        assigns[:invite].should == invite
        session[:invite_id].should == invite_id
      end

      it 'succeeds for a targeted invite' do
        Rubicon::UntargetedInvite.expects(:find).with(invite_id).returns(nil)
        Rubicon::Invite.expects(:find).with(invite_id).returns(invite)
        get :show, id: invite_id
        assigns[:invite].should == invite
        session[:invite_id].should == invite_id
      end

      it 'fails when the invite does not exist' do
        Rubicon::UntargetedInvite.expects(:find).with(invite_id).returns(nil)
        Rubicon::Invite.expects(:find).with(invite_id).returns(nil)
        get :show, id: invite_id
        response.status.should == 404
      end
    end

    context 'with a logged in user' do
      before { act_as_stub_user }

      it "redirects to the home page" do
        get :show, id: invite_id
        response.should be_redirected_to_home_page
      end
    end
  end
end
