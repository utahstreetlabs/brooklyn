module Notifications
  module Tracking
    # Base class for notifications about a tracking number
    class BaseExhibit < Notifications::BaseExhibit
      def i18n_scope
        "exhibits.notifications.tracking"
      end
    end
  end
end
