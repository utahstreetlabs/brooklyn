module Notifications
  module User
    # Base class for notifications about a user.
    class BaseExhibit < Notifications::BaseExhibit
      def i18n_scope
        "exhibits.notifications.user"
      end
    end
  end
end
