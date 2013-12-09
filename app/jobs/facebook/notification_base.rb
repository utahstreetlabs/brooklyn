require 'ladon'
require 'brooklyn/sprayer'

module Facebook
  class NotificationBase < Ladon::Job
    include Brooklyn::Sprayer

    @queue = :facebook

    def self.listing_path(listing, options = {})
      url_helpers.listing_path(listing, options)
    end

    def self.profile_path(user, options = {})
      url_helpers.public_profile_path(user, options)
    end

    def self.root_path(options = {})
      url_helpers.root_path(options)
    end

    def self.view_context
      ActionController::Base.helpers
    end

    # Return all users that commented on +listing+
    def self.commenters(listing, actor)
      summaries = Listing.comment_summaries([listing.id], actor)
      return [] unless summaries[listing.id]
      User.where(id: summaries[listing.id].commenter_ids)
    end

    # Return all users that liked +listing+
    def self.likers(listing)
      liker_ids = listing.likes_summary.liker_ids
      User.where(id: liker_ids)
    end
  end
end
