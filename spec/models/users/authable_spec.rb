require 'spec_helper'

describe Users::Authable do
  let(:provider) { :facebook }
  let(:uid) { '0012345678' }
  let(:person) { FactoryGirl.create(:person) }
  let(:auth) do
    Hashie::Mash.new(uid: uid, user_info: {}, credentials: {}, info: {email: 'g.love@specialsauce.com',
      first_name: 'G.', last_name: 'Love', name: 'G. Love'})
  end
  let(:identity) { nil }

  describe '#find_or_create_from_oauth!' do
    context 'with an existing profile and person' do
      let(:rubi_profile) { stub('rubicon-profile', id: 'a1b2c3', uid: uid, person_id: person.id, network: provider) }

      before do
        Identity.expects(:find_by_provider_id!).with(Network.klass(provider), rubi_profile.uid).returns(identity)
      end

      context 'and the profile is not connected' do
        it 'connects a new user to the existing profile / person' do
          Profile.expects(:find_for_uid_and_network).with(uid, provider).returns(Profile.new(rubi_profile))
          Identity.expects(:create_from_oauth!)
          user = User.find_or_create_from_oauth!(Network.klass(provider), auth)
          expect(user.person).to eq(person)
        end
      end
    end
  end

  describe '#add_identity_from_oauth' do
    let(:user) { FactoryGirl.create(:registered_user, person: person) }
    let(:existing_identity) { nil }
    let(:new_identity) { stub('identity') }
    let(:network_class) { Network.klass(provider) }
    before do
      Identity.expects(:find_by_provider_id).with(network_class, uid).returns(existing_identity)
    end

    context 'when there is no existing identity' do
      it 'succeeds' do
        Identity.expects(:create_from_oauth!).with(user, network_class, auth).returns(new_identity)
        user.add_identity_from_oauth(network_class, auth).should == new_identity
      end

      it 'raises ConnectionFailure on exception' do
        Identity.expects(:create_from_oauth!).with(user, network_class, auth).raises(LadonDecorator::RecordNotSaved)
        expect { user.add_identity_from_oauth(network_class, auth) }.to raise_error(ConnectionFailure)
      end
    end

    context 'when there is an existing identity' do
      context 'and it belongs to the current user' do
        let(:existing_identity) { Identity.new(stub('identity', user_id: user.id)) }
        it 'updates' do
          existing_identity.expects(:update_from_oauth!).with(auth).returns(existing_identity)
          user.add_identity_from_oauth(network_class, auth).should == existing_identity
        end
      end

      context 'and it belongs to a different user' do
        let(:existing_identity) { Identity.new(stub('identity', user_id: user.id + 1)) }
        it 'fails' do
          expect { user.add_identity_from_oauth(network_class, auth) }.
            to raise_exception(ExistingConnectedProfile)
        end
      end
    end
  end

  describe '#update_oauth_token' do
    let(:user) { FactoryGirl.create(:registered_user, person: person) }
    let(:uid) { '8905672341' }
    let(:other_uid) { '90896745231' }
    let(:identity) { stub('identity', uid: uid) }
    let(:request) { 'not-really-signed' }
    let(:code) { 'abcdef' }

    context 'with a valid signed request' do
      before do
        Network::Facebook.expects(:parse_signed_request).with(request).returns({code: code, user_id: uid})
        user.expects(:identity_for).with(:facebook).returns(identity)
        identity.expects(:code=).with(code)
        identity.expects(:save!)
      end
      it 'works' do
        user.update_oauth_token(provider, signed: request)
      end
    end

    context 'without a valid signed request' do
      before do
        Network::Facebook.expects(:parse_signed_request).with(request).returns(nil)
        identity.expects(:code=).never
        identity.expects(:save!).never
      end
      it 'raises an exception' do
        expect { user.update_oauth_token(provider, signed: request) }.to raise_exception(InvalidCredentials)
      end
    end

    context 'with a signed request for the wrong user' do
      before do
        Network::Facebook.expects(:parse_signed_request).with(request).returns({code: code, user_id: other_uid})
        user.expects(:identity_for).with(:facebook).returns(identity)
        identity.expects(:code=).never
        identity.expects(:save!).never
      end
      it 'raises an exception' do
        expect { user.update_oauth_token(provider, signed: request) }.to raise_exception(InvalidCredentials)
      end
    end
  end

  context "when authenticating credentials" do
    let(:user) { FactoryGirl.create(:registered_user) }
    let(:username) { 'jamespage' }
    let(:password) { 'skiffle' }

    describe '#authenticate_with_password' do
      context "when provided valid credentials" do
        before { User.expects(:authenticate).returns(user) }

        it "finds user" do
          User.authenticate_with_password(username, password).should == user
        end
      end

      context "when provided invalid credentials" do
        before { User.expects(:authenticate).returns(nil) }

        it "does not find user" do
          User.authenticate_with_password(username, password).should == nil
        end
      end
    end

    describe '#authenticate_with_oauth' do
      let(:profile) { stub('profile') }
      let(:provider) { Network.klass(:facebook) }
      let(:uid) { 12345 }
      let(:token) { 'deadbeef' }
      let(:info) { {name: "James Page", email: "jamespage@thezep.com"} }
      let(:auth) { Hashie::Mash.new(scope: nil, uid: uid, info: info, credentials: {token: token}, extra: {}) }

      context "when provided valid credentials" do
        before do
          User.expects(:find_or_create_from_oauth!).with(provider, auth).returns(user)
          user.person.expects(:for_network).returns(profile)
          profile.expects(:valid_credentials?).returns(true)
        end

        it "returns the user" do
          User.authenticate_with_oauth(provider, uid, token, info).should == user
        end
      end

      context "when provided invalid credentials" do
        context "when user is not found" do
          before do
            User.expects(:find_or_create_from_oauth!).with(provider, auth).returns(nil)
          end

          it "does not return the user" do
            User.authenticate_with_oauth(provider, uid, token, info).should == nil
          end
        end

        context "when credentials can not be externally validated" do
          before do
            User.expects(:find_or_create_from_oauth!).with(provider, auth).returns(user)
            user.person.expects(:for_network).returns(profile)
            profile.expects(:valid_credentials?).returns(false)
          end

          it "does not return the user" do
            User.authenticate_with_oauth(provider, uid, token, info).should == nil
          end
        end
      end
    end
  end
end
