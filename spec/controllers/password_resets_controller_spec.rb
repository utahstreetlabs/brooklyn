require 'spec_helper'

describe PasswordResetsController do
  describe "#new" do
    it "shows the page to an anonymous user" do
      get :new
      response.should be_success
      assigns(:user).should be
    end

    it "disallows a connected user" do
      act_as(FactoryGirl.create(:connected_user))
      get :new
      response.should be_redirected_to_auth_page
    end

    it "disallows a registered user" do
      act_as_stub_user
      get :new
      response.should be_redirected_to_home_page
    end
  end

  describe "#create" do
    context "for a guest" do
      let(:user) { mock() }

      before do
        User.stubs(:generate_reset_password_token).with(email).returns(user)
        user.stubs(:errors).returns(errors)
      end

      context "without errors" do
        let(:email) { 'test@example.com' }
        let(:errors) { []}

        it "sends password instructions to a registered user" do
          user.stubs(:registered?).returns(true)
          subject.class.expects(:send_email).with(:reset_password_instructions, user)
          submit_send_reset_instructions_form(email: email)
          response.should be_redirected_to_home_page
        end

        it "kicks a non-registered user back to the home page" do
          user.stubs(:registered?).returns(false)
          subject.class.expects(:send_email).never
          submit_send_reset_instructions_form(email: email)
          response.should be_redirected_to_home_page
        end
      end

      context "with errors" do
        let(:email) { '' }
        let(:errors) { [:an_error] }

        before do
          subject.class.expects(:send_email).never
        end

        it "assigns user" do
          submit_send_reset_instructions_form(:email => email)
          assigns(:user).should == user
        end

        it "redisplays the page" do
          submit_send_reset_instructions_form(:email => email)
          response.should_not be_redirect
        end
      end
    end

    it "disallows a connected user" do
      act_as FactoryGirl.create(:connected_user)
      submit_send_reset_instructions_form
      response.should be_redirected_to_auth_page
    end

    context "for a registered user" do
      before { act_as_stub_user }

      it "is disallowed" do
        submit_send_reset_instructions_form
        response.should be_redirected_to_home_page
      end
    end

    def submit_send_reset_instructions_form(user_params = {})
      post :create, :user => user_params
    end
  end

  describe "#show" do
    let(:token) { 'token' }

    context "for a guest" do
      let(:user) { mock() }

      context "with a valid token" do
        before do
          User.stubs(:find_by_reset_password_token).with(token).returns(user)
        end

        it "assigns user" do
          visit_password_reset_page
          assigns(:user).should be
        end

        it "renders the page" do
          visit_password_reset_page
          response.should be_success
        end
      end

      context "with an invalid token" do
        before do
          User.stubs(:find_by_reset_password_token).with(token).returns(nil)
        end

        it "assigns user" do
          visit_password_reset_page
          assigns(:user).should_not be
        end

        it "redirects to home page" do
          visit_password_reset_page
          response.should be_redirected_to_home_page
        end
      end
    end

    it "disallows a connected user" do
      act_as FactoryGirl.create(:connected_user)
      visit_password_reset_page
      response.should be_redirected_to_auth_page
    end

    context "for a registered user" do
      before { act_as_stub_user }

      it "is disallowed" do
        visit_password_reset_page
        response.should be_redirected_to_home_page
      end
    end

    def visit_password_reset_page
      get :show, :id => token
    end
  end

  describe "#update" do
    let(:token) { 'token' }

    context "for a guest" do
      let(:user) { mock() }

      before do
        User.stubs(:reset_password_by_token).with(token, password_params).returns(user)
        user.stubs(:errors).returns(errors)
      end

      context "normally" do
        let(:email) { 'test@example.com' }
        let(:password_params) do
          {:password => DEFAULT_PASSWORD, :password_confirmation => DEFAULT_PASSWORD}.stringify_keys!
        end
        let(:errors) { []}

        it "signs in and absorbs the guest" do
          controller.expects(:sign_in_and_absorb_guest).with(user)
          submit_reset_password_form(password_params)
          response.should be_redirected_to_home_page
          flash[:notice].should be
        end
      end

      context "with errors" do
        let(:email) { '' }
        let(:password_params) { {:password => '', :password_confirmation => ''}.stringify_keys! }
        let(:errors) { [:an_error] }

        it "does not sign in or absorb the guest" do
          controller.expects(:sign_in_and_absorb_guest).never
          submit_reset_password_form(password_params)
          response.should render_template(:show)
          assigns(:user).should == user
        end
      end
    end

    it "disallows a connected user" do
      act_as FactoryGirl.create(:connected_user)
      submit_reset_password_form
      response.should be_redirected_to_auth_page
    end

    context "for a registered user" do
      before { act_as_stub_user }

      it "is disallowed" do
        submit_reset_password_form
        response.should be_redirected_to_home_page
      end
    end

    def submit_reset_password_form(user_params = {})
      post :update, :id => token, :user => user_params
    end
  end
end
