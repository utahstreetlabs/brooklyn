module Users
  module Authable
    extend ActiveSupport::Concern

    def add_identity_from_oauth(provider, auth)
      identity = Identity.find_by_provider_id(provider, auth.uid)
      if identity
        raise ExistingConnectedProfile unless identity.belongs_to_user?(self)
        identity.update_from_oauth!(auth)
      else
        begin
          Identity.create_from_oauth!(self, provider, auth)
        rescue LadonDecorator::RecordNotSaved
          raise ConnectionFailure.new("Unable to create identity from oauth for #{provider.symbol}, uid: #{auth.uid}")
        end
      end
    end

    def update_oauth_token(provider, options = {})
      raise "Only facebook token updates are supported" unless provider == :facebook
      request = Network::Facebook.parse_signed_request(options[:signed])
      raise InvalidCredentials unless request
      if request[:code] && (identity = identity_for(provider))
        raise InvalidCredentials unless identity.uid == request[:user_id]
        identity.code = request[:code]
        identity.save!
      end
    end

    # might build a secondary index inside flying dog later, but for now we can build this using rubicon
    def identity_index
      @identity_index ||= self.person.network_profiles.each_with_object({}) do |(network,profile),index|
        if identity = Identity.find_by_provider_id(network, profile.uid)
          identity.profile = profile
          index[network] = identity
        end
      end
    end

    def identities
      identity_index.values
    end

    def identity_for(provider)
      identity_index[provider]
    end

    module ClassMethods
      def attrs_from_oauth(auth, options)
        info = auth.info
        attrs = { name: info.name, email: info.email }
        nameparts = info.name.split(' ')
        attrs[:firstname] = info.first_name || nameparts.first
        attrs[:lastname] = info.last_name || nameparts.last
        attrs
      end

      def create_from_oauth!(provider, auth, options = {})
        profile = Profile.find_for_uid_and_network(auth.uid, provider.symbol)
        raise ExistingConnectedProfile if profile && profile.user && !profile.user.guest?

        person = profile ? profile.person : Person.create!
        user = person.build_user(attrs_from_oauth(auth, options).merge(options.fetch(:user, {})))
        user.connect!
        user
      end

      def find_or_create_from_oauth!(provider, auth, options = {})
        info = auth.info
        identity = Identity.find_by_provider_id!(provider, auth.uid)
        logger.debug("found identity #{identity} for provider #{provider.symbol} and uid #{auth.uid}")
        if identity
          # things always seem to get crazy in reg, so handle this inconsistent state the best we can
          unless user = self.where(id: identity.user_id).first
            user = create_from_oauth!(provider, auth, options)
            identity.user_id = user.id
          end
          identity.update_from_oauth!(auth)
        else
          unless info.email && user = User.where(email: info.email).first
            user = create_from_oauth!(provider, auth, options)
          end
          # XXX: need to deal with case where this user object has an identity for this provider
          identity = Identity.create_from_oauth!(user, provider, auth)
        end
        user
      end

      def authenticate_with_password(username, password)
        benchmark 'Authenticated credentials', level: :info do
          User.authenticate(username, password)
        end
      end

      def authenticate_with_oauth(provider, uid, token, options = {})
        scope = (options[:scope] && options[:scope].is_a?(Array)) ? options[:scope].join(',') : options[:scope]
        auth = Hashie::Mash.new(scope: scope, uid: uid, credentials: { token: token }, extra: {})
        auth.info = options.slice(:name, :email)
        user = benchmark "Authenticated #{provider.canonical_name} credentials", level: :info do
          begin
            User.find_or_create_from_oauth!(provider, auth)
          rescue Exception => e
            nil
          end
        end

        # We have the ability to verify a signed request from a client app (authenticating to Facebook from the client
        # js sdk), so there's no need for the old synchronous validation call in the main auth flow. Unfortunately, the
        # Facebook iOS SDK doesn't generate signed requests so we still need to validate that the token is legit
        # via synchronous validation, i.e. +valid_credentials?+, here.
        # A good discussion:
        # http://stackoverflow.com/questions/4623974/design-for-facebook-authentication-in-an-ios-app-that-also-accesses-a-secured-we
        if user
          profile = user.person.for_network(provider.symbol)
          return nil unless profile.valid_credentials?(auth)
        end
        user
      end
    end
  end
end
