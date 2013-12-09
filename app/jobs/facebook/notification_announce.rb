module Facebook
  class NotificationAnnounce < NotificationBase
    @queue = :facebook

    def self.work
      logger.debug("Posting notification to Facebook to all registered users")
      with_error_handling("facebook notification announce") do
        return unless feature_enabled?(:networks, :facebook, :notifications, :action, :announce)
        notification_post
      end
    end

    def self.notification_post
      User.find_registered_person_ids_in_batches(batch_size: Network::Facebook.notification_batch_size) do |pids|
        Profile.find_for_people_and_network(pids, Network::Facebook.symbol).each do |profile|
          Facebook::NotificationAnnouncePost.enqueue(profile.id) if profile.connected?
        end
      end
    end
  end
end
