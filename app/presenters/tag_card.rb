class TagCard < FeedCard
  attr_accessor :tag, :photos, :liked

  def initialize(story, viewer, options = {})
    super
    # a tag card can be created based on a tag rather than a story. in that case, we have to cope with a nil
    # story here in the initializer.
    @tag = options[:tag] || (story.tag if story)
    @photos = options.fetch(:photos, [])
    @liked = options.fetch(:liked, false)
  end

  def liked?
    !!liked
  end

  class << self
    def eager_fetch_for_collection(cards, options = {})
      listing_index = eager_fetch_listings(cards, options)
      eager_fetch_photos(cards, listing_index, options)
      eager_fetch_likes(cards, options)
    end

    # Finds the listings whose photos will be displayed for each card.
    #
    # @param [Hash] options
    # @option options [Integer] :listings_per_card
    def eager_fetch_listings(tag_cards, options = {})
      if tag_cards.any?
        listing_count = options.fetch(:listings_per_card, 0)
        tag_cards.each_with_object({}) do |card, m|
          m[card] = Listing.visible_ids_for_tag_id(card.tag.id, listing_count)
        end
      else
        {}
      end
    end

    # Sets the photos to display for each card.
    #
    # @param [Hash] options
    def eager_fetch_photos(tag_cards, listing_idx, options = {})
      if tag_cards.any?
        listing_ids = listing_idx.values.flatten.compact.uniq
        # find the primary photos for each card's listings
        photo_idx = ListingPhoto.find_primaries(listing_ids)
        tag_cards.each do |card|
          card.photos = listing_idx[card].map {|id| photo_idx[id]}
        end
      end
    end

    # Sets whether or not the viewer likes each card's tag.
    #
    # @param [Hash] options
    def eager_fetch_likes(tag_cards, options = {})
      if tag_cards.any? && tag_cards.first.viewer
        tag_ids = tag_cards.map {|c| c.tag.id}
        like_idx = tag_cards.first.viewer.like_existences(:tag, tag_ids)
        tag_cards.each do |card|
          card.liked = like_idx[card.tag.id]
        end
      end
    end
  end
end
