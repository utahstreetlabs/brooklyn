module Controllers
  module NotificationPill
    extend ActiveSupport::Concern

    included do
      helper_method :unviewed_notification_count, :poll_notifications?
    end

  protected
    def unviewed_notification_count
      @unviewed_notification_count ||= poll_notifications? ? current_user.unviewed_notification_count : 0
    end

    def suppress_notification_polling
      @notification_polling_suppressed = true
    end

    def poll_notifications?
      logged_in? && !@notification_polling_suppressed
    end
  end
end
