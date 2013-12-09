require 'spec_helper'

describe Signup::Invites::EmailController do
  describe '#index' do
    it_behaves_like "secured against anonymous users" do
      before { do_get }
    end

    context 'as a logged-in user' do
      include_context "for a logged-in user"

      it 'succeeds' do
        do_get
        response.should render_template(:index)
      end
    end

    def do_get
      get :index
    end
  end

  describe '#create' do
    let(:invite_params) { {} }

    it_behaves_like "secured against anonymous users" do
      before { do_create }
    end

    context 'as a logged-in user' do
      include_context "for a logged-in user"

      it 'succeeds when invite is valid' do
        invite = stub('invite', valid?: true)
        EmailInvite.expects(:new).with(invite_params).returns(invite)
        Invites::EmailContext.expects(:send_messages).with(controller.current_user, invite)
        do_create
        response.should redirect_to(signup_onboard_path)
      end

      it 'fails when invite is invalid' do
        invite = stub('invite', valid?: false)
        EmailInvite.expects(:new).with(invite_params).returns(invite)
        Invites::EmailContext.expects(:send_messages).never
        do_create
        response.should render_template(:index)
      end
    end

    def do_create
      post :create, invite: invite_params
    end
  end
end
