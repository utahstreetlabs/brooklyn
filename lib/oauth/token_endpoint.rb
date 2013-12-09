require 'ladon'
require 'rack/oauth2'
require 'rack/oauth2/server'
require 'rack/oauth2/access_token'

FORM_HASH = "rack.request.form_hash"

module OAuth
  # A Rack application that handles OAuth2 access token requests as described at
  # http://tools.ietf.org/html/draft-ietf-oauth-v2-26#section-3.2.
  #
  # Based on https://github.com/nov/rack-oauth2-sample/blob/master/lib/token_endpoint.rb. Thanks nov!
  class TokenEndpoint
    include ActiveSupport::Benchmarkable
    include Ladon::ErrorHandling
    include Ladon::Logging

    def call(env)
      benchmark 'Processed with token endpoint', level: :info do
        authenticator(attrs_hash(env[FORM_HASH])).call(env)
      end
    end

    # Generate a new bearer token for an authenticated user.  Handles a subset of OAuth2 grant types.
    # @param [Hash] options path parameters parsed by rack
    # @option options [String] :network network given token is associated with (grant type = :client_credentials)
    # @option options [String] :uid user id for provided network associated with credentials (grant type = :client_credentials)
    def authenticator(options = {})
      Rack::OAuth2::Server::Token.new do |req, res|
        user = case req.grant_type
        when :password
          User.authenticate_with_password(req.username, req.password) or
            req.invalid_grant!
        when :client_credentials
          # required: client_id, client_secret (token), uid, network
          provider = Network.klass(options[:network]) if options[:network]
          uid = options[:uid]
          info = options[:user].slice(:name, :email) if options[:user]
          info[:scope] = req.scope if req.scope

          req.invalid_client! unless (req.client_id && req.client_secret)
          req.invalid_request! unless (provider && uid)

          user = User.authenticate_with_oauth(provider, uid, req.client_secret, info) or
            req.invalid_request!
          # A user that is connceted requires onboarding.  Set this in the response
          # for the client to handle by passing the state back to the client.
          res.header['X-Copious-User-State'] = user.state
          user
        else
          req.unsupported_grant_type!
        end

        begin
          api_config = user.find_or_create_api_config
        rescue Exception => e
          error!("Create API config", e, user_id: self.id)
        end
        res.access_token = Rack::OAuth2::AccessToken::Bearer.new(access_token: api_config.token)
      end
    end

    def error!(message, exception, params = {})
      self.class.handle_error(message, exception, params)
      description = exception.message if Rails.env.development?
      raise Rack::OAuth2::Server::Abstract::ServerError.new(:server_error, description)
    end

    def attrs_hash(options = {})
      Hashie::Mash.new(options)
    end
  end
end
