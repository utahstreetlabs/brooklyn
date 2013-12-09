require 'spec_helper'

describe OAuth::TokenEndpoint do
  include Rack::Test::Methods

  def app
    OAuth::TokenEndpoint.new
  end

  let(:url) { '/oauth/token' }
  let(:client_id) { 'test-client' }
  let(:params) { {} }
  let(:rack_env) { {} }

  context 'when grant type is password' do
    let(:grant_type) { 'password' }

    before { params['grant_type'] = grant_type }

    context 'and client id is provided' do
      before { params['client_id'] = client_id }

      context 'and valid credentials are provided' do
        let!(:user) { FactoryGirl.create(:registered_user) }
        let(:password) { 'deadbeef' }

        before do
          params['username'] = user.email
          params['password'] = password
          User.stubs(:authenticate_with_password).with(user.email, password).returns(user)
        end

        context 'and user has a token' do
          let!(:api_config) { FactoryGirl.create(:api_config, user: user) }
          before { post url, params }
          subject { ActiveSupport::JSON.decode(last_response.body) }

          its(['access_token']) { should == api_config.token }
        end

        context 'and user does not have a token' do
          before { post url, params }
          subject { ActiveSupport::JSON.decode(last_response.body) }

          its(['access_token']) { should be }
        end
      end

      context 'and invalid credentials are provided' do
        before do
          params['username'] = 'username'
          params['password'] = 'password'
          User.stubs(:authenticate_with_password).returns(nil)
          post url, params
        end  
        subject { ActiveSupport::JSON.decode(last_response.body) }

        its(['error']) { should == 'invalid_grant' }
      end

      context 'and credentials missing' do
        before { post url, params }
        subject { ActiveSupport::JSON.decode(last_response.body) }

        its(['error']) { should == 'invalid_request' }
        its(['error_description']) { should include('username') }
        its(['error_description']) { should include('password') }
      end
    end

    context 'and client id is missing' do
      before { post url, params }
      subject { ActiveSupport::JSON.decode(last_response.body) }

      its(['error']) { should == 'invalid_request' }
      its(['error_description']) { should include('client_id') }
    end
  end

  context 'when grant type is client_credentials' do
    let(:grant_type) { 'client_credentials' }
    let(:scope) { 'publish_actions' }

    before { params['grant_type'] = grant_type }

    context 'and invalid parameters are provided' do
      let(:uid) { '/oauth/token' }

      before { post url, params }
      subject { ActiveSupport::JSON.decode(last_response.body) }

      its(['error']) { should == 'invalid_request' }
    end

    context 'and valid parameters are provided' do
      let!(:network) { 'facebook' }
      let!(:uid) { 12345 }
      let!(:name) { "James Page" }
      let!(:email) { "jamespage@thezep.com" }
      let(:url) { "/oauth/token" }

      before { rack_env["rack.request.form_hash"] = { network: network, uid: uid, user: { name: name, email: email } } }

      context 'and client credentials are provided' do
        let(:token) { 'deadbeef' }

        before do
          params['client_id'] = client_id
          params['client_secret'] = token
          params['scope'] = scope
        end

        context 'and valid credentials are provided' do
          let(:user) { FactoryGirl.create(:registered_user) }
          let(:api_config) { FactoryGirl.create(:api_config, user: user, token: token) }

          before do
            User.expects(:authenticate_with_oauth).with(Network.klass(network), uid, token, is_a(Hash)).returns(user)
            user.expects(:find_or_create_api_config).returns(api_config)
            post url, params, rack_env
          end
          subject { ActiveSupport::JSON.decode(last_response.body) }

          its(['access_token']) { should == api_config.token }

          it "sets the X-Copious-User-State header" do
            last_response.header['X-Copious-User-State'].should == 'registered'
          end
        end

        context 'and invalid credentials are provided' do
          before do
            User.expects(:authenticate_with_oauth).with(Network.klass(network), uid, token, is_a(Hash)).returns(nil)
            post url, params, rack_env
          end
          subject { ActiveSupport::JSON.decode(last_response.body) }

          its(['error']) { should == 'invalid_request' }
        end
      end
    end
  end

  context 'when grant type is invalid' do
    before do
      params['grant_type'] = 'foobar'
      post url, params
    end
    subject { ActiveSupport::JSON.decode(last_response.body) }

    its(['error']) { should == 'unsupported_grant_type' }
  end

  context 'when grant type is missing' do
    before { post url, params }
    subject { ActiveSupport::JSON.decode(last_response.body) }

    its(['error']) { should == 'invalid_request' }
    its(['error_description']) { should include('grant_type') }
  end
end
