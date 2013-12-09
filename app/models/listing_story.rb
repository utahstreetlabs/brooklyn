# Models stories that reside in Rising Tide.
class ListingStory < Story
  decorates RisingTide::Story
  attr_accessor :listing, :photo, :collection

  # Returns whether or not the story's listing and photo exist.
  #
  # @param [Hash] options
  # @option options [Boolean] :no_listings when true, does not consider listing or photo for completeness
  # @return [Boolean]
  def complete?(options = {})
    return false unless super() or (types.present? and types.any?) or (actor_ids.present? and actor_ids.any?)
    return true if options[:no_listings] == true
    not listing.nil? and not photo.nil?
  end

  def incomplete?(options = {})
    not complete?(options)
  end

  def users
    return @users if @users
    @users = begin
      return super unless [:listing_multi_actor, :listing_multi_actor_multi_action].include?(type)
      case type
      when :listing_multi_actor then
        User.where(id: actor_ids.uniq).order(:name)
      when :listing_multi_actor_multi_action then
        User.where(id: types.values.flatten.uniq).order(:name)
      end
    end
  end

  # Returns the most recent stories for each identified listing.
  #
  # @param [Array] listing_ids the ids of the listings to fetch stories for
  # @param [Hash] options
  # @return [Hash] a lookup table of listing id to stories
  # @see RisingTide::Story#find_most_recent_for_listings
  # @see #resolve_associations
  def self.find_most_recent_for_listings(listing_ids, options = {})
    if listing_ids.any?
      Rails.logger.debug("Finding most recent stories for listings #{listing_ids}")
      idx = decorated_class.find_most_recent_for_listings(listing_ids, options)
      stories = idx.values.flatten.map {|s| new(s)}
      stories = resolve_associations(stories, options)
      idx = listing_ids.inject({}) {|m, id| idx.merge!(id => [])}
      stories.inject(idx) {|m, s| m[s.listing_id] << s if s.complete?(options); m}
    else
      {}
    end
  end

  # Returns the most recent story for a single listing.
  #
  # @param [Integer] listing_id the id of the listing to fetch a story for
  # @param [Hash] options
  def self.find_most_recent_for_listing(listing_id, options = {})
    story_idx = ListingStory.find_most_recent_for_listings(Array.wrap(listing_id))
    story_idx[listing_id].first if story_idx.any?
  end

  # Returns the provided array of stories after populating each story with its associated listing and photo. Only
  # listings that are displayable in a feed (as per +Listing.find_feed_displayable+) are fetched.
  #
  # @param [Array] stories
  # @return [Array] the same list of stories, now populated (hopefully) with listings and photos
  def self.eager_fetch_listings(stories)
    if stories.any?
      listing_ids = stories.map(&:listing_id)
      listings = Listing.find_feed_displayable(stories.map(&:listing_id), includes: {seller: :person})
      listing_idx = listings.inject({}) {|m, l| m.merge(l.id => l)}
      photo_idx = ListingPhoto.find_primaries(listings)
      stories.each do |s|
        s.listing = listing_idx[s.listing_id]
        s.photo = photo_idx[s.listing_id]
      end
    end
    stories
  end

  def self.eager_fetch_collections(stories)
    if stories.any?
      collections = Collection.where(id: stories.map(&:collection_id))
      collection_idx = collections.each_with_object({}) { |c, m| m[c.id] = c }
      stories.each do |s|
        s.collection = collection_idx[s.collection_id]
      end
    end
    stories
  end

  # Returns the provided stories after resolving listing associations.
  #
  # @param [Array] stories the stories whose associations are to be resolved
  # @param [Hash] options options controlling association resolution
  # @option options [Boolean] :no_listings when true, does not eager fetch listings
  # @return [Array] the stories with resolved associations
  def self.resolve_associations(stories, options = {})
    stories = super(stories, options)
    stories = eager_fetch_listings(stories) unless options[:no_listings] == true
    eager_fetch_collections(stories.select { |s| s.type == :listing_saved })
    stories
  end
end
