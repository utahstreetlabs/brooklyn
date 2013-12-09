require 'oauth/http_authentication'

module Controllers
  module TokenAuthable
    extend ActiveSupport::Concern
    include OAuth::HttpAuthentication::BearerToken::ControllerMethods

    # Supports Basic authentication for backward compatibility, but defaults to OAuth bearer token authentication.
    def authenticate_token(realm = nil)
      auth = Rack::Auth::AbstractRequest.new(request.env)
      @user = if auth.provided? && auth.scheme == :basic
        # the token is sent in the username portion of the credentials. the password portion is ignored.
        authenticate_or_request_with_http_basic(realm) do |token, garbage|
          ApiConfig.authenticate_token(token)
        end
      else
        authenticate_or_request_with_oauth_bearer_token(realm) do |token|
          ApiConfig.authenticate_token(token)
        end
      end
    end

    module ClassMethods
      def authenticate_token(options = {})
        before_filter(options.except(:realm)) { authenticate_token(options[:realm]) }
      end
    end
  end
end
