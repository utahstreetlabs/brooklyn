require 'lagunitas/models/notification'

module Users
  module Notifiable
    extend ActiveSupport::Concern

    # Returns the user's most recent notifications.
    #
    # @option options [Integer] :page (1)
    # @option options [Integer] :per (+#notifications_per_page+)
    # @option options [Boolean] :mark_viewed
    # @return [Ladon::PaginatableArray]
    # @see Lagunitas::Notification#find_most_recent_for_user
    def recent_notifications(options = {})
      options[:per] ||= self.class.notifications_per_page
      logger.debug("Finding recent notifications for user #{self.id} with options #{options}")
      Lagunitas::Notification.find_most_recent_for_user(self.id, options)
    end

    def clear_notification(notification_id)
      logger.debug("Deleting notification #{notification_id} for user #{self.id}")
      Lagunitas::Notification.delete(self.id, notification_id)
    end

    def unviewed_notification_count
      logger.debug("Counting unviewed notifications for user #{self.id}")
      Lagunitas::Notification.count_unviewed_for_user(self.id)
    end

    # @option options [DateTime] :before clear only notifications viewed before this time
    def clear_viewed_notifications(options = {})
      logger.debug("Clearing viewed notifications for user #{self.id} with options #{options}")
      Lagunitas::Notification.delete_viewed_for_user(self.id, options)
    end

    def mark_all_notifications_viewed
      Notification.mark_all_viewed_for_user(self.id)
    end

    module ClassMethods
      # @option options [DateTime] :before clear only notifications viewed before this time
      def clear_viewed_notifications(options = {})
        logger.debug("Clearing viewed notifications for all users with options #{options}")
        Lagunitas::Notification.delete_viewed(options)
      end

      def notifications_per_page
        Brooklyn::Application.config.users.notifications.per_page
      end

      def notifications_autoclear_viewed_period
        Brooklyn::Application.config.users.notifications.autoclear_viewed_period
      end
    end
  end
end
