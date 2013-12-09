require 'ladon'

module Users
  class AutoclearViewedNotificationsJob < Ladon::Job
    @queue = :users

    # @param [Integer] before only clear notifications that were viewed at least this many seconds ago
    def self.work(before = nil)
      before ||= User.notifications_autoclear_viewed_period.ago
      with_error_handling("Auto clearing viewed notifications", before: before) do
        User.clear_viewed_notifications(before: before)
      end
    end
  end
end
