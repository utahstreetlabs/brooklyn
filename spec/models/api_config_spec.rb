require 'spec_helper'

describe ApiConfig do
  describe '.generate_token_if_necessary' do
    context 'when creating without a token' do
      it 'generates a token' do
        ac = FactoryGirl.create(:api_config)
        ac.token.should be
      end

      it 'ensures uniqueness of the generated token' do
        ac1 = FactoryGirl.create(:api_config)
        token = 'this is a token'
        SecureRandom.stubs(:urlsafe_base64).returns(ac1.token).then.returns(token)
        ac2 = FactoryGirl.create(:api_config)
        ac2.token.should == token
      end
    end

    context 'when creating with a token' do
      it 'does not generate a new token' do
        token = 'this is a token'
        ac = FactoryGirl.create(:api_config, token: token)
        ac.token.should == token
      end
    end
  end

  describe '#authenticate_token' do
    context 'when token is blank' do
      subject { ApiConfig.authenticate_token(nil) }
      it { should be_nil }
    end

    context 'when token cannot be found' do
      subject { ApiConfig.authenticate_token('foobar') }
      it { should be_nil }
    end

    context 'when user is not registered' do
      let(:user) { FactoryGirl.create(:inactive_user) }
      let(:api_config) { FactoryGirl.create(:api_config, user: user) }
      subject { ApiConfig.authenticate_token(api_config.token) }
      it { should be_nil }
    end

    context 'when user is registered' do
      let(:user) { FactoryGirl.create(:registered_user) }
      let(:api_config) { FactoryGirl.create(:api_config, user: user) }
      subject { ApiConfig.authenticate_token(api_config.token) }
      it { should == user }
    end
  end
end
