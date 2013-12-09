module Controllers
  # Provides utilities for manipulating user flows
  #
  # The simplest example of this is redirecting a user back to a page
  # after registration or login.
  #
  # Helpers are provided to facilitate register and login flows. To
  # use them you can call:
  #
  # store_register_redirect(redirectable)
  #
  # +redirectable+ can be a String (or anything Rails'
  # redirect_to method accepts), an Array of Strings, or a Symbol.
  #
  # When redirect_for is called (eg, by redirect_after_register) it
  # will first try to look redirectable up in a class-level registry
  # of redirect types. This registry will return either a redirectable
  # String or Array or a Proc. If it returns a Proc, redirect_for will
  # evaluate the Proc and use its result (which, again, may be a
  # String or Array of Strings).
  #
  # Post-registration actions will call redirect_after_register, which
  # will redirect to the url you stored and reset the
  # register-redirect state.
  #
  # To implement new flows, you can use the +store_redirect+
  # and +redirect_for+ methods directly. See the register and login
  # helpers for examples.
  module Flowable
    extend ActiveSupport::Concern

    included do
      helper_method :redirect_path
    end

    module ClassMethods
      # generate a key to store or lookup a redirect path in the session
      def redirect_key(name)
        "redirect:#{name}"
      end

      def registered_redirects
        @@registered_redirects ||= HashWithIndifferentAccess.new
      end

      def register_redirects(name, redirects=nil, &block)
        registered_redirects[name] = (redirects || lambda(&block))
      end

      def store_login_redirect(options = {})
        before_filter :store_login_redirect, options
      end

      def skip_store_login_redirect(options = {})
        skip_filter :store_login_redirect, options
      end
    end

    module InstanceMethods
      ### login redirects ###

      def store_login_redirect(url=request.url)
        store_redirect_for(:login, url)
      end

      def redirect_after_login(default=nil)
        unless update_oauth_tokens?
          redirect_for(:login, default)
        end
      end

      def stored_login_redirect
        stored_redirect_path(:login)
      end

      def stored_redirect
        stored_login_redirect || stored_auth_redirect || stored_register_redirect
      end

      ### registration redirects ###

      def store_register_redirect(url=request.url)
        store_redirect_for(:reg, url)
      end

      def redirect_after_register(default=nil)
        redirect_for(:reg, default)
      end

      def store_auth_redirect(url=request.url)
        store_redirect_for(:auth, url)
      end

      def redirect_after_auth(default=nil)
        redirect_for(:auth, default)
      end

      def redirect_to_stored(default=nil)
        if stored_login_redirect
          redirect_after_login
        elsif stored_auth_redirect
          redirect_after_auth
        elsif stored_register_redirect
          redirect_after_register
        else
          redirect_to(default || root_path)
        end
      end

      def stored_auth_redirect
        stored_redirect_path(:auth)
      end

      def stored_register_redirect
        stored_redirect_path(:reg)
      end

      def redirect_after_onboarding_check(user, request)
        if user.needs_onboarding
          user.update_attribute(:needs_onboarding, false)
          redirect_to_stored(signup_buyer_interests_path)
        else
          redirect_to_stored(request)
        end
      end

      protected

      def redirects_for(name)
        redirects = self.class.registered_redirects[name]
        if redirects
          realized_redirects = redirects.is_a?(Proc) ? instance_eval(&redirects) : redirects
          realized_redirects.is_a?(Array) ? realized_redirects.map {|n| redirects_for(n)}.flatten : redirects_for(realized_redirects)
        else
          name
        end
      end

      def stored_redirects(name)
        session[self.class.redirect_key(name)]
      end

      def stored_redirect_path(name)
        paths = stored_redirects(name)
        paths.is_a?(Array) ? paths.first : paths
      end

      # Path to send user to when they are done whatever flow is provided by +name+.
      # If this name was not stored, the default will be returned.
      # If no default is provided, the root_path will be returned.
      def redirect_path(name, default = nil)
        stored_redirect_path(name) || default || root_path
      end

      def store_redirect_url_for(name, url)
        session[self.class.redirect_key(name)] = url
      end

      # redirectable can be a symbol or an array or a url
      def store_redirect_for(name, redirectable)
        # we never want to redirect a user to an xhr url, so disallow at this level
        store_redirect_url_for(name, redirects_for(redirectable)) unless request.xhr?
      end

      def redirect_for(name, default=nil)
        redirect_to(redirect_path(name, default))
        reset_redirect_for(name)
      end

      # Check the request parameters for a 'redirect=NAME'and store the referer so that when the current flow is complete,
      # the user can be returned to where they started.
      def store_redirect
        if params.key?(:redirect)
          store_redirect_url_for(params[:redirect], request.referer)
        end
      end

      def reset_redirect_for(name)
        paths = stored_redirects(name)
        store_redirect_url_for(name, paths.is_a?(Array) ? paths.pop : nil)
      end
    end
  end
end
