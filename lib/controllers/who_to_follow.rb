module Controllers
  # Provides common behaviors for controllers/views that include the who to follow module
  module WhoToFollow
    extend ActiveSupport::Concern

    module InstanceMethods
    protected
      def load_follow_suggestions
        @follow_suggestions = current_user.follow_suggestions
        @follow_connections = SocialConnection.all(current_user, @follow_suggestions)
      end
    end

    module ClassMethods
      def load_follow_suggestions(options = {})
        before_filter(options) { load_follow_suggestions }
      end
    end
  end
end
