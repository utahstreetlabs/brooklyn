require 'spec_helper'

describe Connect::Invites::FacebookController do
  describe '#search' do
    let(:name) { 'eeeee' }

    it_behaves_like "xhr secured against anonymous users" do
      before { do_search }
    end

    context 'as a logged-in user' do
      include_context "for a logged-in user"

      it_behaves_like 'xhr not available to those not connected to facebook' do
        before { do_search }
      end

      context "when the user is connected to facebook" do
        include_context 'connected to facebook'

        it 'succeeds' do
          html = 'BLAHBLAH'
          Invites::FacebookDirectShareContext.expects(:eligible_profiles).
            with(controller.current_user, has_entries(name: name, renderer: controller)).returns(html)
          do_search
          response.should be_jsend_success
          response.jsend_data['results'].should == html
        end
      end
    end

    def do_search
      xhr :get, :search, name: name, format: :json
    end
  end

  describe '#create' do
    let(:invite_params) { {} }

    it_behaves_like "secured against anonymous users" do
      before { do_create }
    end

    context 'as a logged-in user' do
      include_context "for a logged-in user"

      it_behaves_like 'not available to those not connected to facebook' do
        before { do_create }
      end

      context "when the user is connected to facebook" do
        include_context 'connected to facebook'

        it 'succeeds when invite is valid' do
          invite = stub('invite', valid?: true, ids: ['cafebebe', 'deadbeef'])
          FacebookInvite.expects(:new).with(invite_params).returns(invite)
          Invites::FacebookDirectShareContext.expects(:async_send_direct_shares).with(controller.current_user, invite)
          do_create
          response.should redirect_to(connect_invites_path)
          flash[:invited].should == invite.ids.size
        end

        it 'fails when invite is invalid' do
          invite = stub('invite', valid?: false)
          FacebookInvite.expects(:new).with(invite_params).returns(invite)
          Invites::FacebookDirectShareContext.expects(:async_send_direct_shares).never
          do_create
          flash[:alert].should have_flash_message('connect.invites.facebook.invite_error')
          response.should redirect_to(connect_invites_path)
        end
      end
    end

    def do_create
      post :create, invite: invite_params
    end
  end
end
