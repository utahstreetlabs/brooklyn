require 'brooklyn/sprayer'
require 'ladon/error_handling'

class ApplicationController < ActionController::Base
  include Stats::Trackable
  include Brooklyn::Instrumentation # used for custom events
  include Brooklyn::Sprayer
  include Brooklyn::Urls
  include Controllers::SessionExpirable
  include Controllers::DoesAnalytics
  include Controllers::ABTestable
  include Controllers::MessageDisplayable
  include Controllers::Flowable
  include Controllers::DisplayRequestable
  include Controllers::ListingsFeed
  include Controllers::StateTransitionable
  include Controllers::SignupFlow
  include Controllers::UserStash
  include Controllers::Instrumentation # used for controller events
  include Controllers::Autologin
  include Controllers::NotificationPill
  include Controllers::SignupOffer
  include Controllers::Mixpanel
  include Controllers::HelloSociety
  include Concerns::FollowFriends
  # must be last controller include so feature flag cache is dumped at the end of the filter chain
  include Controllers::FeatureFlags
  include Ladon::ErrorHandling
  include ::SslRequirement

  # thanks to http://www.perfectline.ee/blog/custom-dynamic-error-pages-in-ruby-on-rails for showing us how it's
  # done Rails 3 style
  unless Rails.application.config.consider_all_requests_local
    # later registrations take precedence over earlier ones, so let the most general one be first
    rescue_from Exception, :with => :respond_error
    rescue_from CanCan::AccessDenied, :with => :respond_unauthorized
    rescue_from ActiveRecord::RecordNotFound, :with => :respond_not_found
    rescue_from ActionController::RoutingError, :with => :respond_not_found
    rescue_from ActionController::UnknownController, :with => :respond_not_found
    rescue_from ActionController::UnknownAction, :with => :respond_not_found
  end

  rescue_from Controllers::SessionExpired, :with => :respond_session_timed_out

  ssl_allowed :all
  protect_from_forgery
  helper_method :current_user, :anonymous_user?, :guest?, :logged_in?, :connected?, :admin?,
    :suppress_login_header, :show_login_header?, :auth_path, :absolute_url, :feature_enabled?
  set_mixpanel_context
  remember_mixpanel_superproperties

  # Sets a flash message at level +key+. The translated message is looked up in the scope of the controller's name
  # under the key +kind+.
  def set_flash_message(key, kind, options = {})
    # XXX: clear any other flash messages that might already be set because we don't have a story for displaying
    # multiple flash messages, of the same type or of mixed types. sucks wet farts from dead pigeons' asses, etc.
    flash.clear
    # XXX: don't set the flash in XHR requests by default, because in
    # nearly all cases, setting the flash in an XHR will actually show
    # the flash message on the next non-XHR request, which is pretty
    # much always confusing. more dead pigeon asses.
    if !request.xhr? || options.delete(:xhr)
      msg = localized_flash_message(kind, options)
      now = options.delete(:now)
      if now
        flash.now[key] = msg
      else
        flash[key] = msg
      end
    end
  end

  def self.require_login_only
    before_filter :require_login_only
  end

  def self.skip_requiring_login_only(options = {})
    skip_filter :require_login_only, options
  end

  def self.ensure_login_or_guest(options = {})
    before_filter :ensure_login_or_guest, options
  end

  def self.require_login_or_guest(options = {})
    before_filter :require_login_or_guest, options
  end

  def self.require_admin(options = {})
    before_filter :require_admin, options
  end

  require_login_only
  update_last_accessed
  enable_autologin
  store_login_redirect unless: :logged_in?

  class << self
    attr_reader :flash_scope
  end

  def self.set_flash_scope(scope)
    @flash_scope = scope
  end

protected
  def set_helpers
    ControllerObserverBase.controller = self
  end
  prepend_before_filter :set_helpers

  # our +Session+ object emulates the rails session with some additional features, so we just swap it in for anyone
  # trying to access the rails session
  def session
    unless defined?(@session)
      storage = super
      @session = Session.new(storage) if storage
    end
    @session
  end

  # A before filter that ensures the user making the request is either logged in or a guest. If neither of those
  # conditions holds, a guest user is created. +guest_user+ will subseqently return that user and
  # +guest?+ will subsequently return true.
  def ensure_login_or_guest
    unless logged_in? || guest?
      user = User.create_guest!
      store_guest(user)
      @guest_user = user # save a query when guest_user is subsequently called
    end
  end

  # A before filter that redirects to the home page unless the current request was made by a logged-in user.
  def require_login_only
    unless logged_in?
      logger.debug("Disallowing as user is not logged in")
      store_login_redirect
      store_register_redirect
      respond_unauthorized
    end
    disable_autologin
  end

  # A before filter that redirects to the home page unless the current request was made by an unregistered but
  # connected user.
  def require_connection_only
    unless connected?
      logger.warn("Disallowing as user is not connected to a network only")
      respond_unauthorized
    end
    disable_autologin
  end

  # A before filter that redirects to the home page unless the current request was made by a logged-in or
  # connected user.
  def require_connection_or_login
    unless logged_in? || connected?
      logger.warn("Disallowing as user is not logged in or connected to a network")
      respond_unauthorized
    end
    disable_autologin
  end

  # A before filter that returns an unauthorized response unless the current request was made by a logged-in or
  # guest user.
  def require_login_or_guest
    unless logged_in? || guest?
      logger.warn("Disallowing as user is not a guest or logged in")
      respond_unauthorized
    end
  end

  # A before filter that returns an unauthorized response unless the current request was made by a user who is not logged
  # in (but may be connected to a network).
  def require_not_logged_in
    if logged_in?
      logger.warn("Disallowing as user is logged in")
      respond_unauthorized
    end
    disable_autologin
  end

  # A before filter that returns an unauthorized response unless the current request was made by an anonymous
  # user (not logged in, not connected to a network.
  def require_anonymous
    if logged_in? || connected?
      logger.warn("Disallowing as user is logged in or connected to a network")
      respond_unauthorized
    end
    disable_autologin
  end

  # A before filter that responds unauthorized unless the current user is an admin
  def require_admin
    unless admin?
      logger.warn("Disallowing as user is not an admin")
      respond_unauthorized
    end
  end

  # XXX: should be forbidden/403
  def respond_unauthorized
    flash.keep
    if request.xhr?
      respond_to do |format|
        format.json { render_jsend(:error => 'Unauthorized', :code => 401) }
        format.html { render :text => 'Unauthorized', :status => 401 }
      end
    else
      if logged_in?
        stored_redirect.present?? redirect_to_stored : redirect_to(root_path)
      else
        redirect_to(signup_path_with_flow_destination)
      end
    end
  end

  def respond_not_found
    respond_to do |format|
      if request.xhr?
        format.json { render_jsend(error: 'Not Found', code: 404) }
      else
        format.html { render 'errors/not_found', status: 404, layout: 'application' }
      end
      format.all { render text: 'Not Found', status: 404 }
    end
  end

  def respond_error(exception)
    log_stack_trace("Unknown error", exception)
    notify_airbrake(exception)
    if request.xhr?
      respond_to do |format|
        format.json { render_jsend(error: 'Internal Server Error', :code => 500) }
        format.all { render :text => 'Internal Server Error', :status => 500 }
      end
    else
      render 'errors/server_error'
    end
  end

  def respond_session_timed_out
    sign_out
    if request.xhr?
      respond_to do |format|
        format.json { render_jsend(:error => 'Session timed out', :code => 499) }
        format.html { render :text => 'Session timed out', :status => 499 }
      end
    else
      set_flash_message(:notice, :timeout, scope: :sessions, timeout: Brooklyn::Application.config.session.timeout_in / 60)
      store_login_redirect
      redirect_to(root_path)
    end
  end

  def current_user_id
    session && session[:user_id]
  end

  # Returns a +User+ representing the currently logged-in user
  def current_user
    @current_user ||= User.with_person(current_user_id) if current_user_id
  end

  # Returns a +User+ representing the current guest user, if any.
  def guest_user
    begin
      @guest_user ||= User.find(session[:guest_id]) if session && session[:guest_id]
    rescue ActiveRecord::RecordNotFound
      remove_guest
      nil
    end
  end

  # Returns true if a logged-in user made the current request.
  def logged_in?
    !!(current_user && current_user.registered?)
  end

  def connected?
    current_user && current_user.connected?
  end

  # Returns true if a guest user made the current request.
  def guest?
    !logged_in? && session && session[:guest_id].present? && guest_user
  end

  # Returns true if a not-logged-in user made the current request (may still be connected to a network or a guest,
  # though).
  # XXX: rename to unauthenticated_user?
  def anonymous_user?
    ! logged_in?
  end

  # Returns true if the current user is an admin
  def admin?
    logged_in? && current_user.admin?
  end

  def auth_path(network, redirect_or_options = {})
    options = if redirect_or_options && redirect_or_options.is_a?(Hash)
      redirect_or_options
    else
      {redirect: redirect_or_options}
    end
    qs = []
    qs << "r=#{options[:redirect]}" if options[:redirect]
    qs << "scope=#{options[:scope]}" if options[:scope]
    qs << "d=#{options[:d]}" if options[:d]
    qs << (options.key?(:seller_signup) ? 's=s' : 's=b')
    path = "/auth/#{(Network.klass(network).as_secure if request.ssl?) || network}"
    path << "?#{qs.join('&')}" if qs.any?
    path
  end

  # Adds the logged-in credential for +person+ to the session.
  def sign_in(user)
    session.sign_in(user)
  end

  # Removes the logged-in user credential from the session.
  def sign_out
    session.sign_out
  end

  def sign_in_and_absorb_guest(user)
    # the current user may not be the guest if the current user just
    # transitioned from a connected user, so just look for the
    # existence of a guest user
    if guest_user
      user.absorb_guest!(guest_user)
      remove_guest
    end
    sign_in(user)
  end

  # Stores the guest user in the session.
  def store_guest(user)
    session[:guest_id] = user.id
  end

  # Removes the guest user from the session.
  def remove_guest
    session.delete(:guest_id)
  end

  # If authenticated user's oauth token permissions are missing
  # any that are designated as required, send them through the
  # authentication process.  Note that by forcing a user through
  # the auth process by means of a redirect we can only force
  # the update of one network per login.
  def update_oauth_tokens?
    # For each connected network, determine the token permissions used
    # to connect to the network.  If we don't have the minimum required
    # permissions and it's a registration network, invalidate the tokens
    # and send the user through the auth process.  If it's not a registration
    # network, disconnect the network and set a flash.
    return false unless current_user
    current_user.person.missing_required_network_permissions.map do |network|
      if current_user.person.connected_networks.include?(network)
        current_user.person.for_network(network).disconnect!
        if Network.klass(network).registerable?
          fire_event(:update_scope, user: current_user, network: network)
          redirect_to(auth_path(network))
        else
          # Set flash, but continue on our way
          set_flash_message(:notice, :disconnected, network: network)
        end
        return true
      end
    end
    false
  end

  # Retrieves a translated flash message in the scope of the controller's name under the key +kind+.
  def localized_flash_message(kind, options = {})
    scope = options.delete(:scope) || self.class.flash_scope
    if scope
      options[:scope] = scope =~ /^controllers/ ? scope : "controllers.#{scope}"
    else
      options[:scope] = "controllers.#{controller_name}"
    end
    options[:default] = Array(options[:default]).unshift(kind.to_sym)
    message = I18n.t(kind, options)
    message.html_safe if message.present?
  end

  # Don't show the login header when rendering a view in this controller
  def suppress_login_header
    @login_header_suppressed = true
  end

  # Determine whether or not to show the login header when rendering a view from this controller.
  def show_login_header?
    return !@login_header_suppressed
  end

  def log_stack_trace(msg, e)
    logger.error("#{e.class} (#{e.message}):")
    e.backtrace.each { |f| logger.error("  #{f}") }
  end
end
