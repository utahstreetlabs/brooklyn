require 'spec_helper'

describe Dashboard::Invites::ProfilesController do
  describe "#update" do
    let(:invitee_id) { '4e680eec50a79914b200006' }

    it_behaves_like "xhr secured against anonymous users" do
      before { send_invitation }
    end

    it "creates an invite for a user" do
      user = act_as_stub_user
      user.person.expects(:invite!).with(invitee_id, is_a(Proc)).returns(stub('invite'))
      send_invitation
      response.should be_jsend_success
    end

    it_behaves_like "an action that handles feed errors properly" do
      let(:exception_thrower) do
        user = act_as_stub_user
        Rubicon::Profile.stubs(:find).with(invitee_id).returns(stub('profile', network: 'facebook'))
        user.person.expects(:invite!).with(invitee_id, is_a(Proc))
      end
      let(:action) { send_invitation }
    end

    def send_invitation
      xhr :put, :update, format: :json, id: invitee_id
    end
  end
end
