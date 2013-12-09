require 'spec_helper'

describe Connect::Invites::EmailController do
  describe '#create' do
    let(:invite_params) { {} }

    it_behaves_like "secured against anonymous users" do
      before { do_create }
    end

    context 'as a logged-in user' do
      include_context "for a logged-in user"

      it 'succeeds when invite is valid' do
        invite = stub('invite', valid?: true, addresses: [mock, mock, mock])
        EmailInvite.expects(:new).with(invite_params).returns(invite)
        Invites::EmailContext.expects(:send_messages).with(controller.current_user, invite)
        do_create
        response.should redirect_to(connect_invites_path)
        flash[:invited].should == invite.addresses.size
      end

      it 'fails when invite is invalid' do
        invite = stub('invite', valid?: false)
        EmailInvite.expects(:new).with(invite_params).returns(invite)
        Invites::EmailContext.expects(:send_messages).never
        do_create
        flash[:alert].should have_flash_message('connect.invites.email.invite_error')
        response.should redirect_to(connect_invites_path)
      end
    end

    def do_create
      post :create, invite: invite_params
    end
  end
end
