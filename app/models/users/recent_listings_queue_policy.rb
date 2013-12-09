module Users
  # Chooses representative listings based on a user's recent activity (as defined by the user's recent listings queue).
  # Tries to fill up to half of the available slots with the listings most recently created by the user, then fills
  # the remaining available space with other listings the user has recently interacted with.
  class RecentListingsQueuePolicy < RepresentativeListingsPolicy
    def find_candidate_listing_ids(users)
      logger.debug("Finding candidate listings for users #{users.map(&:id)}")
      max_listed = listing_count/2
      users.each_with_object({}) do |user, m|
        ids = []
        if user.recent_listed_listing_ids.any?
          ids.concat(user.recent_listed_listing_ids.values.uniq.reverse.take(max_listed))
        end
        max_other = listing_count - ids.size
        if max_other > 0 && user.recent_saved_listing_ids.any?
          ids.concat(user.recent_saved_listing_ids.values.uniq.reverse.reject { |id| id.in?(ids) }.take(max_other))
        end
        max_other = listing_count - ids.size
        if max_other > 0 && user.recent_listing_ids.any?
          ids.concat(user.recent_listing_ids.values.uniq.reverse.reject { |id| id.in?(ids) }.take(max_other))
        end
        m[user.id] = ids.map(&:to_i)
      end
    end
  end
end
