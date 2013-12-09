require 'rack/oauth2/server'

module OAuth
  module HttpAuthentication
    # Rails helpers for OAuth2 bearer token authentication
    #
    # === Example
    #
    #    class ListingsController < ApplicationController
    #      before_filter :authenticate_or_request_with_oauth_bearer_token do |token|
    #        AccessToken.valid?(token)
    #      end
    #    end
    module BearerToken
      extend self

      module ControllerMethods
        extend ActiveSupport::Concern

        def authenticate_or_request_with_oauth_bearer_token(realm = nil, &login_procedure)
          authenticate_with_oauth_bearer_token(&login_procedure) || request_oauth_bearer_token_authentication(realm)
        end

        def authenticate_with_oauth_bearer_token(&login_procedure)
          OAuth::HttpAuthentication::BearerToken.authenticate(request, &login_procedure)
        end

        def request_oauth_bearer_token_authentication(realm = 'Application')
          OAuth::HttpAuthentication::BearerToken.authentication_request(self, realm)
        end
      end

      def authenticate(request, &login_procedure)
        req = Rack::OAuth2::Server::Resource::Bearer::Request.new(request.env)
        begin
          req.setup!
        rescue Rack::OAuth2::Server::Abstract::Error
          # req.oauth2? will return false
        end
        req.oauth2? && login_procedure.call(req.access_token)
      end

      def authentication_request(controller, realm)
        controller.headers['WWW-Authenticate'] = %Q{Bearer realm="#{realm}", error="invalid_token"}
        controller.render(json: {error: :invalid_token}, status: :unauthorized)
      end

      def encode_credentials(token)
        "Bearer #{token}"
      end
    end
  end
end
