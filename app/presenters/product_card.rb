class ProductCard < FeedCard
  attr_accessor :listing, :photo, :connection, :liked, :likes, :collection, :featured, :saved, :saves, :remove_from_feed

  def initialize(story, viewer, options = {})
    super
    # a product card can be created based on a listing rather than a story. in that case, we have to cope with a nil
    # story here in the initializer.
    @listing = options[:listing] || (story.listing if story)
    @photo = options[:photo] || (story.photo if story)
    @connection = options[:connection]
    @featured = options.fetch(:featured, false)
    @liked = options.fetch(:liked, false)
    @likes = options.fetch(:likes, 0)
    @saved = options.fetch(:saved, false)
    @saves = options.fetch(:saves, 0)
    @collection = options[:collection]
    @remove_from_feed = options.fetch(:remove_from_feed, false)
  end

  def liked?
    !!liked
  end

  class << self
    def eager_fetch_for_collection(cards, options = {})
      super
      Array.wrap(options[:fetch]).each {|f| self.send(:"eager_fetch_#{f}", cards, options)}
      eager_fetch_likes(cards, options)
      eager_fetch_saves(cards, options)
      eager_fetch_latest_actors(cards, options)
      eager_fetch_features(cards, options)
    end

    def eager_fetch_stories(cards, options = {})
      story_idx = ListingStory.find_most_recent_for_listings(listings.map(&:id), options)
      cards.each do |card|
        stories = story_idx[card.listing.id]
        card.story = stories.is_a?(Array) ? stories.first : stories
      end
    end

    def eager_fetch_likes(cards, options = {})
      if cards.any?
        listing_ids = cards.map {|c| c.listing.id}
        existence_idx = cards.first.viewer.like_existences(:listing, listing_ids) if cards.first.viewer
        count_idx = Listing.like_counts(listing_ids)
        cards.each do |card|
          card.liked = existence_idx.fetch(card.listing.id, false)
          card.likes = count_idx.fetch(card.listing.id, 0)
        end
      end
    end

    def eager_fetch_saves(cards, options = {})
      if cards.any? && cards.first.viewer
        saves = cards.first.viewer.saves_for_listings(cards.map { |c| c.listing.id})
        saves_idx = saves.each_with_object({}) { |save, idx| idx[save.listing_id] = true }
        count_idx = Listing.saves_counts(cards.map { |c| c.listing.id })
        cards.each do |card|
          card.saved = saves_idx.fetch(card.listing.id, false)
          card.saves = count_idx.fetch(card.listing.id, 0)
        end
      end
    end

    def eager_fetch_features(cards, options = {})
      if cards.any? && cards.first.viewer
        features_counts_idx = Listing.features_counts_for_listings(cards.map { |c| c.listing.id})
        cards.each do |card|
          card.featured = features_counts_idx.fetch(card.listing.id, 0) > 0
        end
      end
    end

    def eager_fetch_latest_actors(cards, options = {})
      if cards.any?
        actor_ids = cards.map { |c| c.story.latest_type_actor_id.last if c.story }.compact.uniq
        actors_idx = User.registered.where(id: actor_ids).each_with_object({}) { |user, idx| idx[user.id] = user }
        cards.each do |card|
          if card.story
            type, actor_id = card.story.latest_type_actor_id
            card.story.latest_type_actor = [type, actors_idx[actor_id]]
          end
        end
      end
    end
  end
end
