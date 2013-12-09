require 'spec_helper'

describe Controllers::TokenAuthable, type: :controller do
  class TokenAuthableController < ActionController::Base
    include Controllers::TokenAuthable
  end

  controller(TokenAuthableController) do
    authenticate_token

    def index
      head(:ok)
    end
  end

  describe '.authenticate_token' do
    let(:token) { 'token' }
    let(:user) { mock('user') }
    before { ApiConfig.stubs(:authenticate_token).with(token).returns(user) }

    context 'when basic credentials are provided' do
      before do
        @request.env["HTTP_AUTHORIZATION"] = ActionController::HttpAuthentication::Basic.encode_credentials(token, '')
      end

      it 'assigns the user for the token' do
        get :index
        assigns(:user).should == user
      end
    end

    context 'when an oauth bearer token is provided' do
      before do
        @request.env["HTTP_AUTHORIZATION"] = OAuth::HttpAuthentication::BearerToken.encode_credentials(token)
      end

      it 'assigns the user for the token' do
        get :index
        assigns(:user).should == user
      end
    end
  end
end
