require 'spec_helper'

describe Settings::PasswordController do
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
    let(:user_params) do
      {'current_password' => DEFAULT_PASSWORD, 'password' => 'deadbeef', 'password_confirmation' => 'deadbeef'}
    end

    it_behaves_like "secured against anonymous users" do
      before { submit_form }
    end

    context "for a logged-in user" do
      let(:user) { act_as_stub_user }

      before do
        user.expects(:current_password=).with(user_params['current_password'])
        user.expects(:password=).with(user_params['password'])
        user.expects(:password_confirmation=).with(user_params['password_confirmation'])
        user.expects(:validate_completely!)
      end

      it "updates the password when valid" do
        user.expects(:save).returns(true)
        submit_form
        response.should redirect_to(settings_password_path)
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
end
