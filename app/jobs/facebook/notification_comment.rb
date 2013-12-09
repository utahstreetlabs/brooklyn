module Facebook
  class NotificationComment < NotificationBase
    @queue = :facebook

    def self.work(listing_id, commenter_id)
      logger.debug("Posting notification to Facebook for comment on listing #{listing_id} by user #{commenter_id}")
      with_error_handling("facebook notification comment", listing_id: listing_id, commenter_id: commenter_id) do
        listing = Listing.find(listing_id)
        commenter = User.find(commenter_id)
        notification_post(listing, commenter)
      end
    end

    # Notifications for likes/loves are posted to friends that have listed, loved, or
    # commented on the same listing.
    def self.notification_post(listing, commenter)
      commenter_profile = commenter.person.for_network(Network::Facebook.symbol)
      return unless commenter_profile

      users = Set.new
      users = users.merge(commenters(listing, commenter))
      users = users.merge(likers(listing))
      users = users.merge(listing.savers)
      users = users.add(listing.seller)
      users = users.delete(commenter)
      profiles = Profile.find_for_people_and_network(users.to_a.map(&:person_id), Network::Facebook.symbol)
      friend_profiles = commenter_profile.follows_in(profiles).uniq

      friend_profiles.each do |p|
        Facebook::NotificationCommentPost.enqueue(listing.id, p.id, commenter_profile.id)
      end
    end
  end
end
