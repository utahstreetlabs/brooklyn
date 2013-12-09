module Controllers
  # session expiration logic. thanks to http://madkingsmusings.blogspot.com/2011/05/session-timeouts-on-rails.html
  # for the basics
  module SessionExpirable
    def self.included(base)
      base.extend(ClassMethods)
      base.class_eval <<-CODE
        around_filter :check_session_expiration, :if => :logged_in?
      CODE
    end

    # Performs session expiration management before and after the action method is called.
    #
    # Before the action, if the session has expired, forgets the session and the current user's remember and then
    # raises +SessionExpired+.
    #
    # After the action, touches the session to keep it fresh.
    def check_session_expiration
      if session_expired?
        session.forget!
        current_user.forget_me!
        raise SessionExpired
      end
      yield
      session.touch!
    end

  protected
    def session_expired?
      # if the remember exists but has expired, the current session may still be active
      current_user.remember_exists_and_not_expired?? false : session.expired?
    end

    module ClassMethods
      def skip_checking_session_expiration
        skip_filter :check_session_expiration
      end
    end
  end

  class SessionExpired < Exception; end
end
