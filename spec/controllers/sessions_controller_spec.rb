require 'spec_helper'

describe SessionsController do
  let(:user) { stub_user 'William McKinley', needs_onboarding?: false }

  context "#new" do
    it 'does not set the login redirect url' do
      get :new
      session.should_not have_redirect(:login)
    end

    it 'prefills the email field from request param' do
      get :new, email: user.email
      assigns[:login].email.should == user.email
    end
  end

  context "#create" do
    let(:login) { stub('login', user: user) }
    before { Login.expects(:new).returns(login) }

    context "with valid credentials" do
      before do
        login.stubs(:valid?).returns(true)
        subject.expects(:begin_login_session)
      end

      it "redirects to the login redirect url" do
        subject.expects(:redirect_after_login)
        # generates a ActionView::MissingTemplate stack trace because we're stubbing out redirect_after_login.
        # nothing to be concerned about; the test still passes.
        submit_login_form(user.email)
      end

      it 'returns a jsend success' do
        submit_login_form(user.email, xhr: true)
        response.should be_jsend_success
      end
    end

    context "with invalid credentials" do
      let(:bogus_password) { 'ugh' }

      before do
        login.stubs(:valid?).returns(false)
        errors = stub('errors', full_messages: 'Negatory')
        login.stubs(:errors).returns(errors)
        subject.expects(:begin_login_session).never
      end

      it "renders the new template" do
        submit_login_form(user.email, password: bogus_password)
        response.should render_template(:new)
      end

      it 'returns a jsend failure' do
        submit_login_form(user.email, password: bogus_password, xhr: true)
        response.should be_jsend_failure
      end
    end

    def submit_login_form(email, options = {})
      login_params = options.reverse_merge(email: email, password: DEFAULT_PASSWORD)
      if options[:xhr]
        xhr :post, :create, login: login_params
      else
        post :create, login: login_params
      end
    end
  end

  context "#destroy" do
    before do
      act_as_stub_user(user: user)
      subject.stubs(:clear_stash)
      subject.expects(:end_session).with(user)
    end

    it 'redirects to the home page' do
      click_logout_link
      response.should be_redirected_to_home_page_without_autologin
    end

    it 'returns a jsend success' do
      click_logout_link(xhr: true)
      response.should be_jsend_success
    end

    def click_logout_link(options = {})
      if options[:xhr]
        xhr :delete, :destroy
      else
        delete :destroy
      end
    end
  end

  context '#begin_login_session' do
    let(:login) { stub('login', user: user, facebook_token: nil, facebook_signed: nil) }

    before do
      subject.expects(:sign_in_and_absorb_guest).with(user)
      subject.expects(:track_usage).with(:login, user: user)
    end

    it 'remembers the user when instructed to' do
      login.stubs(:remember_me?).returns(true)
      user.expects(:remember_me!)
      subject.send(:begin_login_session, login)
    end

    it 'does not remember the user when not instructed to' do
      login.stubs(:remember_me?).returns(false)
      user.expects(:remember_me!).never
      subject.send(:begin_login_session, login)
    end

    it 'updates the facebook auth token when necessary' do
      login.stubs(:remember_me?).returns(false)
      login.stubs(:facebook_signed).returns('notreallybase64==')
      user.expects(:update_oauth_token).with(:facebook, signed: 'notreallybase64==')
      subject.send(:begin_login_session, login)
    end

    it 'does not update profile attributes if token missing' do
      login.stubs(:remember_me?).returns(false)
      user.person.expects(:update_oauth_token).never
      subject.send(:begin_login_session, login)
    end
  end

  context '#end_session' do
    before { subject.expects(:sign_out) }

    it 'forgets the user when one is given' do
      user.expects(:forget_me!)
      subject.send(:end_session, user)
    end

    it 'does not forget the user when one is not given' do
      user.expects(:forget_me!).never
      subject.send(:end_session, nil)
    end
  end
end
