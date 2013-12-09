module Notifications
  module Invite
    # Base class for notifications about an invite.
    class BaseExhibit < Notifications::BaseExhibit
      def locals
        {inviter: inviter, invitee: invitee_profile, invited: invited}
      end

      def i18n_scope
        "exhibits.notifications.invite"
      end
    end
  end
end
