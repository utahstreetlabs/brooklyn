module Controllers
  # Manages interaction with the current user's stash.
  module UserStash
    extend ActiveSupport::Concern

    def update_last_accessed
      current_user.touch_last_accessed if current_user
    end

    def clear_stash
      current_user.clear_stash if current_user
    end

    module ClassMethods
      def skip_updating_last_accessed(options = {})
        skip_filter(:update_last_accessed, options)
      end

      def update_last_accessed(options = {})
        after_filter(:update_last_accessed, options)
      end
    end
  end
end
