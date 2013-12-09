module Notifications
  module Collection
    # Base class for notifications about a collection.
    class BaseExhibit < Notifications::BaseExhibit
      def i18n_scope
        "exhibits.notifications.collection"
      end
    end
  end
end
