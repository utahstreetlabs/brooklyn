module Facebook
  class NotificationLike < NotificationBase
    @queue = :facebook

    def self.work(listing_id, liker_id)
      logger.debug("Posting notification to Facebook for like of listing #{listing_id} by user #{liker_id}")
      with_error_handling("facebook notification like", listing_id: listing_id, liker_id: liker_id) do
        listing = Listing.find(listing_id)
        liker = User.find(liker_id)
        notification_post(listing, liker)
      end
    end

    # Notifications for likes/loves are posted to friends that have listed, loved, or
    # commented on the same listing.
    def self.notification_post(listing, liker)
      liker_profile = liker.person.for_network(Network::Facebook.symbol)
      return unless liker_profile

      users = Set.new(commenters(listing, liker))
      users.merge(likers(listing))
      users.merge(listing.savers)
      users.add(listing.seller)
      users.delete(liker)
      friend_profiles = users.each_slice(Network::Facebook.notification_batch_size).flat_map do |user_batch|
        profiles = Profile.find_for_people_and_network(user_batch.map(&:person_id), Network::Facebook.symbol)
        liker_profile.follows_in(profiles)
      end
      friend_profiles.uniq.each { |p| Facebook::NotificationLikePost.enqueue(listing.id, p.id, liker_profile.id) }
    end
  end
end
