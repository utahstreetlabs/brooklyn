class ActorCard < FeedCard
  attr_accessor :actor, :photos, :visible_listings_count, :likes_count, :collections_count

  def initialize(story, viewer, options = {})
    super
    @actor = options.fetch(:actor, story.actor)
    @photos = options.fetch(:photos, [])
  end

  class << self
    def eager_fetch_for_collection(cards, options = {})
      super
      listing_index = eager_fetch_listings(cards, options)
      eager_fetch_photos(cards, listing_index, options)
      eager_fetch_stats(cards)
    end

    # Finds the listings whose photos will be displayed for each card.
    #
    # @param [Hash] options
    # @option options [Integer] :listings_per_card
    def eager_fetch_listings(actor_cards, options = {})
      if actor_cards.any?
        actor_cards.each_with_object({}) do |card, m|
          m[card] = card.story.listing_ids
        end
      else
        {}
      end
    end

    # Sets the photos to display for each card.
    #
    # @param [Hash] options
    def eager_fetch_photos(actor_cards, listing_idx, options = {})
      if actor_cards.any?
        listing_ids = listing_idx.values.flatten.compact.uniq
        # find the primary photos for each card's listings
        photo_idx = ListingPhoto.find_primaries(listing_ids, includes: :listing)
        actor_cards.each do |card|
          card.photos = listing_idx[card].map {|id| photo_idx[id]}.compact
        end
      end
    end

    def eager_fetch_stats(actor_cards)
      if actor_cards.any?
        user_ids = actor_cards.map { |card| card.actor.id }.uniq
        collection_idx = User.collection_counts(user_ids)
        like_idx = User.like_counts(user_ids)
        listing_idx = Listing.visible_counts(user_ids)
        actor_cards.each do |card|
          card.collections_count = collection_idx.fetch(card.actor.id, 0)
          card.likes_count = like_idx.fetch(card.actor.id, 0)
          card.visible_listings_count = listing_idx.fetch(card.actor.id, 0)
        end
      end
    end
  end
end
