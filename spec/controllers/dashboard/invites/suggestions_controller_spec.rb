require 'spec_helper'

describe Dashboard::Invites::SuggestionsController do
  describe "#index" do
    let(:blacklist) {['12345']}

    it_behaves_like "secured against anonymous users" do
      before { get_invite_suggestions }
    end

    context "by a user" do
      let(:suggestion){ Rubicon::FacebookProfile.new }
      let(:suggestions){ [suggestion] }

      before do
        user = act_as_stub_user
        user.person.expects(:invite_suggestions).with(1, blacklist: blacklist).returns(suggestions)
        subject.stubs(:inviter_profiles).returns([])
      end

      it "returns jsend" do
        get_invite_suggestions
        assigns[:suggestions].should == suggestions
        response.should be_jsend_success
      end
    end

    def get_invite_suggestions
      get :index, format: :json, blacklist: blacklist
    end
  end

  describe "#destroy" do
    context "by a user" do
      let(:suggestion){ Rubicon::FacebookProfile.new }
      let(:invitee_id) { '4e680eec50a79914b200006' }
      let!(:user) { act_as_stub_user }

      before do
        suggestion.stubs('id').returns(invitee_id)
        suggestion.stubs('network').returns(:facebook)
      end

      it "returns jsend on success" do
        user.person.expects(:blacklist_invite_suggestion).with(invitee_id)
        Rubicon::Profile.expects(:find).returns(suggestion)
        destroy_invite_suggestion
        response.should be_jsend_success
      end

      it "fails" do
        Rubicon::Profile.expects(:find).returns(nil)
        destroy_invite_suggestion
        response.should be_jsend_error
      end

      def destroy_invite_suggestion
        delete :destroy, params = {:id => invitee_id}
      end
    end
  end
end
