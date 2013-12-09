module Notifications
  module Credit
    # Base class for notifications about a credit.
    class BaseExhibit < Notifications::BaseExhibit
      def locals
        {credit: credit, offer: offer}
      end

      def i18n_scope
        "exhibits.notifications.credit"
      end
    end
  end
end
