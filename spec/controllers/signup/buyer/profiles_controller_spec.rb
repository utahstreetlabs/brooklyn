require 'spec_helper'

describe Signup::Buyer::ProfilesController do
  before { subject.stubs(:verify_recaptcha).returns(true) }

  context "#new" do
    context "for an anonymous user" do
      it "should not be allowed" do
        visit_new_profile_page
        response.should be_redirected_to_auth_page
      end
    end

    context "for a connected user" do
      let(:user) do
        stub_user 'Roscoe P. Coltrane',
          email: 'apps+151f2878758105839.3902182.9a0560c384548df4db21857c0690ae@proxymail.facebook.com'
      end
      before { act_as_stub_user user: user, connected: true }

      it 'should prepare the user and render the new page' do
        user.expects(:slugify)
        user.expects(:email=).with(nil)
        visit_new_profile_page
        response.should render_template(:new)
      end
    end

    context "for a registered user" do
      let(:user) { stub_user 'Boss Hogg' }
      before { act_as_stub_user user: user }

      it "should not be allowed" do
        visit_new_profile_page
        response.should be_redirected_to_home_page
      end
    end

    def visit_new_profile_page
      get :new
    end
  end

  context "#create" do
    context "for an anonymous user" do
      it "should not be allowed" do
        submit_register_form
        response.should be_redirected_to_auth_page
      end
    end

    context "for a connected user" do
      let(:user) { stub_user 'Bo Duke', errors: {} }
      let(:signup_path) { signup_buyer_interests_path }
      before do
        act_as_stub_user user: user, connected: true
        user.expects(:attributes=)
        user.expects(:validate_completely!)
        user.expects(:guest_to_absorb=).with(nil)
        subject.expects(:set_visitor_id).with(user)
      end

      context "normally" do
        feature_flag('onboarding.skip_interests', false)
        let(:user_params) do
          {slug: user.name.to_param, email: user.email, password: DEFAULT_PASSWORD,
           password_confirmation: DEFAULT_PASSWORD}
        end
        let(:params) { {user: user_params, publish: '1'} }
        let(:hello_society_referral) { true }

        before do
          user.expects(:register).returns(true)
          subject.expects(:clear_visitor_id_cookie)
          subject.expects(:track_usage).with(:onboarding_create_profile, kind_of(Hash))
          subject.expects(:track_usage).with(:registration_complete, kind_of(Hash))
          subject.stubs(:hello_society_referral?).returns(hello_society_referral)
          subject.stubs(:hello_society_campaign).returns('hams')
          user.expects(:connected_to?).with(:facebook).returns(true)
        end

        context 'with recaptcha' do
          let(:profile) { stub('profile') }

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

        it 'should register and sign in the user and redirect to the next step in the flow' do
          user.expects(:publish_signup!)
          submit_register_form(params)
          session[:user_id].should == user.id
          response.should redirect_to(signup_path)
        end

        it 'should render jsend success if format is json' do
          user.expects(:publish_signup!)
          submit_register_form(params.merge(format: :json))
          response.should be_jsend_success
        end

        it "should succeed if publish_signup fails" do
          user.expects(:publish_signup!).raises(Exception)
          subject.expects(:notify_airbrake)
          submit_register_form(params)
          response.should redirect_to(signup_path)
        end

        context "when creating a profile with interests disabled" do
          feature_flag('onboarding.skip_interests', true)

          it "should redirect to root" do
            user.expects(:complete_onboarding!)
            submit_register_form(params)
            session[:user_id].should == user.id
            response.should redirect_to(root_path)
          end
        end
      end

      context "with errors" do
        let(:params) do
          {user: {slug: user.name.to_param, email: user.email, password: '', password_confirmation: ''}}
        end

        before { user.expects(:register).returns(false) }

        it 'should not register or sign in the user and redisplay the new page' do
          submit_register_form(params)
          subject.send(:logged_in?).should == false
          response.should render_template(:new)
        end

        it 'should render jsend success if format is json' do
          submit_register_form(params.merge(format: :json))
          subject.send(:logged_in?).should == false
          response.should be_jsend_failure
        end
      end
    end

    context "for a registered user" do
      before { act_as(Factory.create(:registered_user)) }

      it "should not be allowed" do
        submit_register_form
        response.should be_redirected_to_home_page
      end
    end

    def submit_register_form(params = {})
      post :create, params
    end
  end
end
