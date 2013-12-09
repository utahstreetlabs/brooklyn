require 'brooklyn/urls'

module Controllers
  # Implements a new design for signup flows.
  #
  # There are two types of signup flow: "buyer" and "seller". A signup flow is entered once the application receives
  # the OAuth callback from the external service and we detect that the user is connected but not yet registered.
  #
  # Since the OAuth flow directly precedes the signup flow, the action which initiates the OAuth flow must
  # communicate which signup flow to enter after the OAuth flow completes. This is done with the request parameter
  # +"s"+.
  # Accepted values for this parameter include:
  #
  #   * +"b"+ => indicates the buyer signup flow
  #   * +"s"+ => indicates the seller signup flow
  #
  # If the parameter value is unknown, or if the parameter is not specified, the buyer flow is used.
  #
  # Before entering the OAuth flow, the controller examines the request parameter and stores the corresponding
  # signup flow type in the session. When the OAuth flow is complete, for connected users, the controller checks the
  # session to determine which signup flow to enter and redirects to the appropriate URL.
  #
  # Each flow has a default destination, but this destination can be overriden by providing the request parameter
  # +"d"+ before entering the OAuth flow. The value of this parameter must be a URL path. If this parameter is provided,
  # the controller stores the destination in the session. When the signup flow is complete, the controller redirects
  # to the override destination, if one was provided, or to its default destination.
  #
  module SignupFlow
    extend ActiveSupport::Concern
    include Brooklyn::Urls

    included do
      helper_method :signup_path_with_flow_destination
    end

    module InstanceMethods
    protected
      # Returns the signup path decorated with the request parameter +:d+ specifying the current request URL as the
      # signup flow destination.
      def signup_path_with_flow_destination(params = {})
        destination = request.url.sub(/#{root_url}/, '')
        destination = "/#{destination}" unless destination.starts_with?('/')
        params[:d] = destination
        "#{signup_path}?#{self.class.as_query_string(params)}"
      end

      def initialize_signup_flow
        [:signup_flow_network, :signup_flow_scope, :signup_flow_type, :signup_flow_destination, :signup_flow_origin_type].each do |k|
          session.delete(k)
        end
      end

      # Stores the signup network in the session; we don't get the network
      # passed to the auth controller in the event of a failure, so we store
      # it in the session.
      def remember_signup_flow_network
        session[:signup_flow_network] = params[:network] if params[:network]
      end

      # Stores the origin type for signup flow so we can support different types
      # of onboarding.  I.e. a user directed to us via a Facebook authenticated
      # referral might get a different onboarding experience than a user
      # that signed up from loh.  Called "origin type" so it isn't confused
      # with referring to an actual location, a la "destination."
      def remember_signup_flow_origin_type
        session[:signup_flow_origin_type] = params[:ot].to_sym if params[:ot]
      end

      # Stores the signup flow scope in the session.
      def remember_signup_flow_scope
        session[:signup_flow_scope] ||= params[:scope]
        # Only set the scope here if necessary; this will override the default
        # in the omniauth strategy for the network.
        if session[:signup_flow_scope].present?
          request.env['omniauth.strategy'].options[:scope] = session[:signup_flow_scope]
        end
      end

      # Stores the signup flow type in the session.
      #
      # @see #determine_signup_flow_type
      def remember_signup_flow_type
        session[:signup_flow_type] ||= determine_signup_flow_type
      end

      # Determines the type of signup flow to use based on +params[:s]+.
      def determine_signup_flow_type
        case params[:s]
        when 's' then :seller
        else :buyer
        end
      end

      def signup_just_registered=(state)
        session[:signup_just_registered] = state
      end

      # Stores the signup flow destination in the session.
      def remember_signup_flow_destination
        session[:signup_flow_destination] ||= determine_signup_flow_destination
      end

      def signup_flow_destination=(destination)
        session[:signup_flow_destination] = destination
      end

      # Determines the destination of the signup flow based on +params[:d]+. Returns +nil+ if the parameter is not
      # present.
      def determine_signup_flow_destination
        params[:d] if params[:d].present?
      end

      # Redirects to the entry point of the signup flow specified in the session or request.
      def redirect_to_signup_flow_entry_point
        flow_type = session.delete(:signup_flow_type) || determine_signup_flow_type
        if (flow_type == :seller || session[:signup_flow_origin_type] == :far)
          # Facebook client-side auth doesn't populate omniauth.origin; we set up signup_flow_destination
          # by passing d=/path/we/came/from as a parameter in the url.
          destination = request.env['omniauth.origin'] || session.delete(:signup_flow_destination)
          store_register_redirect(destination) unless stored_register_redirect
        end

        if flow_type == :seller
          redirect_to(new_profile_path)
        else
          redirect_to(new_signup_buyer_profile_path)
        end
      end
    end
  end
end
