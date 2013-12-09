require 'spec_helper'

describe Settings::EmailController do
  describe "#show" do
    it_behaves_like "secured against anonymous users" do
      before { get :show }
    end

    context "for a logged-in user" do
      before { act_as_stub_user }

      it "shows the page" do
        get :show
        response.should render_template(:show)
      end
    end
  end

  describe "#update" do
    let(:user_params) { {'email' => 'starbuck@galactica.mil', 'email_confirmation' => 'starbuck@galactica.mil'} }

    it_behaves_like "secured against anonymous users" do
      before { submit_form }
    end

    context "for a logged-in user" do
      let(:user) { act_as_stub_user }

      before do
        user.expects(:email=).with(user_params['email'])
        user.expects(:email_confirmation=).with(user_params['email_confirmation'])
      end

      it "updates the email when valid" do
        user.expects(:save).returns(true)
        submit_form
        response.should redirect_to(settings_email_path)
        flash[:notice].should be
      end

      it "re-renders the page when invalid" do
        user.expects(:save).returns(false)
        submit_form
        response.should be_success
        response.should render_template(:show)
        flash[:notice].should_not be
      end
    end

    def submit_form
      put :update, user: user_params
    end
  end

  describe "#update_prefs" do
    let(:user_params) { {'email_prefs' => {'follow_me' => '1'}} }

    it_behaves_like "secured against anonymous users" do
      before { submit_form }
    end

    context "for a logged-in user" do
      let(:user) { act_as_stub_user }

      it "saves the email prefs" do
        user.expects(:save_email_prefs).with(user_params['email_prefs'])
        submit_form
        response.should redirect_to(settings_email_path)
        flash[:notice].should be
      end
    end

    def submit_form
      put :update_prefs, user: user_params
    end
  end
end
