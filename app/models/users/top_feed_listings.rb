require 'active_support/concern'

module Users
  module TopFeedListings
    extend ActiveSupport::Concern

    # Return the "top" listings in a user's feed.
    #
    # Currently orders listings by the number of loves in the feed. The
    # listings will not include listings the user has already loved, and will
    # return at most one listing per seller.
    #
    # Returns a map from listings to ids of users who liked that listing.
    #
    # @param [Hash] options
    # @option options [Integer] :limit the max number of listings to return
    # @returns a map from listings to sets of user ids
    def top_feed_listings(options = {})
      limit = options.fetch(:limit, -1)
      existing_likes = self.likes(limit: -1, type: :listing, attr: [:listing_id]).map(&:listing_id).compact.to_set
      unliked_feed_likes_by_listing = likers_by_listing.reject { |k, v| existing_likes.include?(k) }
      listings = Listing.active.where(id: unliked_feed_likes_by_listing.map(&:first)).
        group_by(&:seller_id).values.map(&:first).
        sort_by { |l| -unliked_feed_likes_by_listing[l.id].count }.
        slice(0..(limit - 1))
      listings.each_with_object({}) { |l, m| m[l] = unliked_feed_likes_by_listing[l.id] }
    end

    private

      # returns a map from listing ids to the user ids of users that
      # liked that listing
      def likers_by_listing
        feed = StoryFeeds::CardFeed.find_slice(limit: 1000, interested_user_id: self.id)
        feed.reduce(Hash.new {|h, k| h[k] = Set.new}) do |h, story|
          case story.type
          when :listing_liked
            h[story.listing_id] << story.actor_id
          when :listing_multi_action
            h[story.listing_id] << story.actor_id if story.types.include?('listing_liked')
          when :listing_multi_actor
            h[story.listing_id] += story.actor_ids if story.action == 'listing_liked'
          when :listing_multi_actor_multi_action
            h[story.listing_id] += story.types['listing_liked'] if story.types.keys.include?('listing_liked')
          when :actor_multi_listing
            if story.action == 'listing_liked'
              story.listing_ids.each do |listing_id|
                h[listing_id] << story.actor_id
              end
            end
          end
          h
        end
      end
  end
end
