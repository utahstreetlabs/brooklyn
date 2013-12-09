require 'spec_helper'

describe ProfileController do
  before { subject.stubs(:verify_recaptcha).returns(true) }

  context "#new" do
    context "for a guest" do
      it "is disallowed" do
        visit_new_profile_page
        response.should be_redirected_to_auth_page
      end
    end

    context "for a connected user" do
      let(:user) { FactoryGirl.create(:connected_user) }
      before do
        act_as user
      end

      it "assigns user" do
        visit_new_profile_page
        assigns(:user).should == user
      end

      it "slugifies user" do
        visit_new_profile_page
        assigns(:user).slug.should be
      end

      it "blanks out email if email is a facebook anon proxy address" do
        user.email = "apps+151f2878758105839.3902182.9a0560c384548df4db21857c0690ae@proxymail.facebook.com"
        user.save!
        visit_new_profile_page
        assigns(:user).email.should be_nil
      end
    end

    context "for a registered user" do
      before { act_as(Factory.create(:registered_user)) }

      it "is disallowed" do
        visit_new_profile_page
        response.should be_redirected_to_home_page
      end
    end

    def visit_new_profile_page
      get :new
    end
  end

  context "#create" do
    context "for a guest" do
      it "is disallowed" do
        submit_register_form
        response.should be_redirected_to_auth_page
      end
    end

    context "for a connected user" do
      let!(:user) { FactoryGirl.create(:connected_user) }
      before do
        act_as user
      end

      it "assigns user" do
        submit_register_form
        assigns(:user).should == user
      end

      context "normally" do
        let(:params) do
          {:slug => user.name.to_param, :email => user.email, :password => DEFAULT_PASSWORD,
            :password_confirmation => DEFAULT_PASSWORD}
        end
        let(:guest_user) { act_as_guest_user }

        context 'with recaptcha' do
          let(:profile) { stub('profile') }

          before do
            subject.stubs(:current_user).returns(user)
          end

          it 'presents a captcha for twitter' do
            user.person.expects(:for_network).with(:twitter).returns(profile)
            subject.expects(:verify_recaptcha).returns(true)
            submit_register_form(params)
          end

          it 'does not present a captcha for facebook' do
            user.person.expects(:for_network).with(:twitter).returns(nil)
            subject.expects(:verify_recaptcha).never
            submit_register_form(params)
          end
        end

        it "registers user" do
          submit_register_form(params)
          assigns(:user).should be_registered
        end

        it "signs in user" do
          submit_register_form(params)
          session[:user_id].should == assigns(:user).id
        end

        it "redirects to home page" do
          submit_register_form(params)
          response.should be_redirected_to_home_page
        end

        it "publishes a story" do
          subject.stubs(:current_user).returns(user)
          user.expects(:publish_signup!)
          submit_register_form(params, publish: '1')
          response.should be_redirect
        end

        it "sets User.visitor_identity" do
          subject.expects(:set_visitor_id).with(user)
          subject.expects(:clear_visitor_id_cookie)
          submit_register_form(params)
          response.should be_redirect
        end

        it "airbrakes but succeeds if publish_signup fails" do
          subject.stubs(:current_user).returns(user)
          user.expects(:publish_signup!).raises(Exception)
          subject.expects(:notify_airbrake)
          submit_register_form(params, publish: '1')
          response.should be_redirect
        end
      end

      context "with errors" do
        let(:params) do
          {:slug => user.name.to_param, :email => user.email, :password => '', :password_confirmation => ''}
        end

        it "does not register user" do
          submit_register_form(params)
          assigns(:user).should_not be_registered
        end

        it "does not sign in user" do
          submit_register_form(params)
          subject.send(:logged_in?).should == false
        end

        it "does not redirect to contact import page" do
          submit_register_form(params)
          response.should_not redirect_to(new_email_account_path)
        end
      end
    end

    context "for a registered user" do
      before { act_as(Factory.create(:registered_user)) }

      it "is disallowed" do
        submit_register_form
        response.should be_redirected_to_home_page
      end
    end

    def submit_register_form(user_params = {}, params={})
      post :create, params.merge(:user => user_params)
    end
  end
end
