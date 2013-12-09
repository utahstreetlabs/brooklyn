require 'spec_helper'

describe AuthController do
  describe "#callback" do
    let(:person) { stub('person', id: user.person_id, user: user) }
    let(:profile) { stub('profile', id: 123, uid: 567, person_id: person.id, network: 'twitter') }
    let(:auth) do
      Hashie::Mash.new(uid: '0012345678', user_info: {}, credentials: {}, extra: {user_hash: {},
        raw_info: {email: 'g.love@specialsauce.com', first_name: 'G.', last_name: 'Love', name: 'G. Love'}})
    end
    let(:strategy) { stub('strategy', options: {:scope => 'read+write'}) }
    let(:visitor_id) { '12345' }
    before { controller.stubs(:visitor_identity).returns(visitor_id) }

    context "with auth" do
      before do
        request.env['omniauth.auth'] = auth
        request.env['omniauth.strategy'] = strategy
        auth.merge!('scope' => request.env['omniauth.strategy'].options.fetch('scope', ""))
      end

      context "for instagram via ssl" do
        let(:network) { Network.klass(:instagram_secure) }
        let!(:user) { act_as_stub_user }

        it "sets secure when omniauth provider is instagram_secure" do
          user.expects(:add_identity_from_oauth).with(network, auth.merge('secure' => true))
          send_callback(:instagram_secure)
        end
      end

      [:twitter, :facebook].each do |n|
        context "for #{n}" do
          let(:network) { n }

          context "with a logged in user" do
            let!(:user) { act_as_stub_user(stubs: {:firstname => 'Testy'}) }
            let!(:network_class) { "Network::#{network.to_s.camelize}".constantize }

            before do
              Network.stubs(:klass).with(network).returns(network_class)
              subject.stubs(:signup_flow_destination).returns(nil)
            end

            context "when scope is default" do
              before do
                network_class.stubs(:scope).returns(auth['scope'])
              end

              context 'and connection succeeds' do
                before do
                  user.expects(:add_identity_from_oauth).with(network_class, auth)
                end

                # XXX: this description doesn't seem to match whatever is being tested
                it "sets scope from strategy" do
                  send_callback(network)
                end

                it "sets flash notice" do
                  send_callback(network)
                  flash[:notice].should have_flash_message('auth.connected',
                    network: I18n.t(:name, scope: [:networks, network]))
                end

                it 'displays a welcome message' do
                  send_callback(network, state: 'w')
                  flash[:notice].should have_flash_message('auth.welcome_existing', name: user.firstname)
                end

                context "when redirecting to signup_flow_destination" do
                  before { session[:signup_flow_destination] = settings_networks_path }

                  it "redirects back to signup flow destination if set" do
                    send_callback(network)
                    expect(response).to redirect_to settings_networks_path
                  end
                end

                it 'returns success jsend' do
                  send_callback(network, json: true)
                  jsend_user_state_should_be 'logged_in'
                end
              end

              context 'and connection fails' do
                before do
                    # XXX: write a test somewhere else to make sure this raise happens
                    user.expects(:add_identity_from_oauth).with(network_class, auth).raises(ConnectionFailure)
                end

                it 'sets flash alert' do
                  send_callback(network)
                  flash[:alert].should have_flash_message('auth.error_connecting',
                                                          network: I18n.t(:name, scope: [:networks, network]))
                end
              end

              context 'and connecting using profile already associated with a different user' do
                before do
                  user.expects(:add_identity_from_oauth).with(network_class, auth).raises(ExistingConnectedProfile)
                end

                it "sets flash alert when connecting with credentials associated with a different user" do
                  send_callback(network)
                  flash[:alert].should have_flash_message('auth.error_network_registered',
                    network: I18n.t(:name, scope: [:networks, network]))
                end
              end
            end

            context "when scope is not default" do
              before do
                network_class.stubs(:scope).returns("foo,bar,baz,quux")
                user.expects(:add_identity_from_oauth).with(network_class, auth)
              end

              it "sets flash notice when connection succeeds and preferences updated" do
                send_callback(network)
                flash[:notice].should have_flash_message('auth.preferences_updated',
                  network: I18n.t(:name, scope: [:networks, network]))
              end
            end
          end

          context "as a non-logged in user" do
            context "who cannot be found from oauth information but is already connected to the network" do
              before do
                User.expects(:find_or_create_from_oauth!).with(Network.klass(network), auth, user: {visitor_id: visitor_id}).
                  raises(ExistingConnectedProfile)
              end

              it 'redirects to login with a flash' do
                send_callback(network)
                expect(response).to redirect_to(login_path)
                flash[:alert].should be
              end

              it 'returns success jsend' do
                send_callback(network, json: true)
                expect(response).to be_jsend_error
              end
            end

            context "who can be found or created from oauth information" do
              let(:user) { stub('connected user', firstname: 'Testy', connected?: true, person_id: 1, id: 1, invite_id: nil) }
              before do
                User.expects(:find_or_create_from_oauth!).with(Network.klass(network), auth, user: {visitor_id: visitor_id}).
                  returns(user)
                controller.stubs(:accept_invite).with(user)
              end

              context "and is not already registered" do
                before do
                  controller.stubs(:visitor_identity).returns(visitor_id)
                  controller.expects(:sign_in).with(user)
                end

                it 'redirects a new user to the buyer signup flow by default' do
                  send_callback(network)
                  expect(response).to redirect_to new_signup_buyer_profile_path
                end

                it 'redirects a new user to the buyer signup flow' do
                  send_callback(network, s: 'b')
                  expect(response).to redirect_to new_signup_buyer_profile_path
                end

                it 'redirects a new user to the seller signup flow' do
                  send_callback(network, s: 's')
                  expect(response).to redirect_to new_profile_path
                end

                it 'displays a welcome message' do
                  send_callback(network, state: 'w')
                  flash[:notice].should have_flash_message('auth.welcome_new', name: user.firstname)
                end

                it 'returns success jsend' do
                  send_callback(network, json: true)
                  jsend_user_state_should_be 'connected'
                end
              end

              context "who has already registered" do
                let (:user) do
                  stub('connected user', firstname: 'Testy', connected?: false, registered?: true, person_id: 1, id: 1, errors: {})
                end

                before do
                  controller.expects(:sign_in_and_absorb_guest).with(user)
                end

                it 'logs a user in and redirects to the home page' do
                  user.expects(:needs_onboarding)
                  send_callback(network)
                  expect(response).to be_redirected_to_home_page
                end

                it "displays a welcome message" do
                  user.expects(:needs_onboarding)
                  send_callback(network, state: 'w')
                  flash[:notice].should have_flash_message('auth.welcome_existing', name: user.firstname)
                end

                it 'returns success jsend' do
                  send_callback(network, json: true)
                  jsend_user_state_should_be 'registered'
                end
              end

              context "with a user that cannot be found from the given auth information" do
                let (:user) { nil }

                it 'redirects to login' do
                  send_callback(network)
                  expect(response).to redirect_to(login_path)
                end

                it 'returns success jsend' do
                  send_callback(network, json: true)
                  expect(response).to be_jsend_error
                end
              end

              context "with auth information corresponding to a non-connected, non-registered user" do

                let (:user) { stub('guest or inactive user', firstname: 'Testy', connected?: false, registered?: false, person_id: 1, id: 1, errors: {}) }

                it 'redirects to login' do
                  send_callback(network)
                  expect(response).to redirect_to(login_path)
                end

                it 'returns success jsend' do
                  send_callback(network, json: true)
                  expect(response).to be_jsend_error
                end
              end
            end
          end
        end
      end

      def send_callback(network, params = {})
        params = params.merge(network: network)
        if params.delete(:json)
          xhr :post, :callback, params.merge(format: :json)
        else
          post :callback, params
        end
      end

      def jsend_user_state_should_be(state)
        expect(response).to be_jsend_success
        response.jsend_data['user_state'].should == state
      end
    end
  end

  describe "#failure" do
    let!(:person) { act_as_stub_user }

    context "with cancelling app authorization" do
      context "with general failure" do
        it 'flash and redirect user to the home page' do
          send_failure()
          flash[:alert].should have_flash_message('auth.error_communicating')
          subject.expects(:notify_airbrake).never
          expect(response).to be_redirected_to_home_page
        end

        it 'returns jsend error' do
          send_failure(json: true)
          expect(response).to be_jsend_error
        end
      end

      context "with invalid credentials" do
        context "when user cancelled adding Facebook timeline permissions" do
          let(:network) { :facebook }
          let!(:network_class) { "Network::#{network.to_s.camelize}".constantize }

          before do
            Network.stubs(:klass).with(network).returns(network_class)
            network_class.stubs(:auth_failure_lambda).returns(lambda { |u| true })
            network_class.stubs(:auth_failure_msg).returns(:facebook_timeline)
          end

          it 'redirects user back to the page they came from' do
            session.expects(:delete).with(:signup_flow_network).returns(network)
            session.expects(:delete).with(:signup_flow_scope).returns(:publish_actions)
            session.expects(:delete).with(:signup_flow_destination).returns(settings_networks_path)
            send_failure(message: 'invalid_credentials')
            flash[:notice].should have_flash_message('auth.facebook_timeline')
            subject.expects(:notify_airbrake).never
            expect(response).to redirect_to settings_networks_path
          end
        end

        it 'redirects user to the home page' do
          send_failure(message: 'invalid_credentials')
          flash[:alert].should have_flash_message('auth.cancelled')
          subject.expects(:notify_airbrake).never
          expect(response).to be_redirected_to_home_page
        end
      end
    end

    def send_failure(params = {})
      if params.delete(:json)
        xhr :post, :failure, params.merge(format: :json)
      else
        post :failure, params
      end
    end
  end

  describe "#prepare" do
    it "should redirect to twitter auth" do
      post :prepare, network: 'twitter'
      expect(response).to redirect_to controller.view_context.auth_path('twitter')
    end

    it "should redirect to facebook auth" do
      post :prepare, network: 'facebook'
      expect(response).to redirect_to controller.view_context.auth_path('facebook')
    end

    it "should default to facebook auth if posted to without a network" do
      post :prepare
      expect(response).to redirect_to controller.view_context.auth_path('facebook')
    end
  end

  describe "#setup" do
    it "should store an auth redirect to root on welcome" do
      subject.expects(:stored_auth_redirect).returns(nil)
      subject.expects(:store_auth_redirect).with(controller.view_context.root_path)
      post :setup, network: 'facebook', state: 'w'
      response.response_code.should == 404
    end

    it "should store a register redirect to the referer for Facebook authenticated referrals" do
      subject.expects(:stored_register_redirect).returns(nil)
      subject.expects(:store_register_redirect).with(request.referer)
      post :setup, network: 'facebook', ot: "far"
      response.response_code.should == 404
    end
  end

  describe '.accept_invite' do
    let(:user) { stub_user 'Jon Smallberries' }

    context 'when the user has already accepted an invite' do
      before do
        user.stubs(:accepted_invite?).returns(true)
      end

      it 'does nothing' do
        user.expects(:accept_invite!).never
        user.expects(:accept_pending_facebook_u2u_invite!).never
        controller.send(:accept_invite, user)
      end
    end

    context 'when the user has not accepted an invite' do
      before do
        user.stubs(:accepted_invite?).returns(false)
      end

      it 'accepts an invite whose code is remembered in the session' do
        code = 'deadbeef'
        session[:invite_id] = code
        user.expects(:accept_invite!).with(code)
        user.expects(:accept_pending_facebook_u2u_invite!).never
        controller.send(:accept_invite, user)
      end

      it 'accepts a Facebook u2u invite' do
        user.expects(:accept_invite!).never
        user.expects(:accept_pending_facebook_u2u_invite!).with(is_a(Hash))
        controller.send(:accept_invite, user)
      end
    end
  end
end
