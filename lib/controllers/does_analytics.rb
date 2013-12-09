module Controllers

  # Provides utilities for working with analytics systems like Mixpanel
  # and Vanity.
  #
  # The concept of a "visitor" is used in this module to represent a
  # single person across signup (ie, starting the first time we see
  # them and persisting throughout their site experience). Technical
  # issues make this difficult to do in all cases (an existing user
  # interacting with the site without signing in is, for example, not
  # tracked correctly at the moment) but this covers the most
  # important use cases for now.
  module DoesAnalytics
    extend ActiveSupport::Concern

    included do
      helper_method :visitor_identity
    end

    module InstanceMethods

      # Returns an id suitable for using in analytics systems like
      # mixpanel and vanity.
      #
      # At the moment, this id is set the first time we see a
      # particular browser and persisted into the User object if that
      # browser goes through signup.
      def visitor_identity
        if current_user and current_user.respond_to?(:visitor_id) and current_user.visitor_id
          current_user.visitor_id
        elsif cookies[:visitor_identity]
          cookies[:visitor_identity]
        else
          id = User.generate_visitor_id
          set_visitor_id_cookie(id)
          id
        end
      end

      def set_visitor_id(user)
        user.visitor_id = cookies[:visitor_identity] if current_user.respond_to?(:visitor_id)
      end

      def set_visitor_id_cookie(visitor_id)
        cookies.permanent[:visitor_identity] = visitor_id
      end

      def clear_visitor_id_cookie
        cookies.delete(:visitor_identity)
      end
    end
  end
end
