module Facebook
  class NotificationPriceAlertJob < NotificationBase
    @queue = :facebook

    def self.work(count)
      user_finder_options = {
        batch_size: Network::Facebook.notification_batch_size,
        limit: count
      }
      logger.debug("Posting price alert notification to #{count} profiles")
      with_error_handling("Post Facebook price alert notification") do
        User.find_most_recent_registered_person_ids_in_batches(user_finder_options) do |person_ids|
          Profile.find_for_people_and_network(person_ids, Network::Facebook).each do |profile|
            NotificationPriceAlertPostJob.enqueue(profile.id) if profile.connected?
          end
        end
      end
    end
  end
end
