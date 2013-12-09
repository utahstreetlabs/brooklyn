# The user card shows a 4x4 grid of listing photos with a user photo superimposed over the middle four grid slots.
# Because those middle four slot are hidden by the user photo, we don't bother fetching listings to fill into those
# slots but instead leave them blank.
class UserCard < FeedCard
  attr_accessor :user, :viewer, :following, :listings, :photos, :listing_count, :collection_count, :like_count,
                :shared_interest

  def initialize(story, viewer, options = {})
    super
    @user = options[:user]
    @following = options.fetch(:following, false)
    @listings = options.fetch(:listings, [])
    @photos = options.fetch(:photos, [])
    @listing_count = options.fetch(:listing_count, 0)
    @collection_count = options.fetch(:collection_count, 0)
    @like_count = options.fetch(:like_count, 0)
    @shared_interest = options[:shared_interest]
  end

  def user_id
    user.id
  end

  class Slot
    attr_reader :position, :listing, :photo

    def initialize(position, options = {})
      @position = position
      @listing = options[:listing]
      @photo = options[:photo]
    end

    def blank?
      listing.nil? && photo.nil?
    end
  end

  def slots
    @slots ||= begin
      results = Array.new(self.class.slot_count)
      self.class.listing_slots.each_with_index do |pos, i|
        results[pos-1] = Slot.new(pos, listing: listings[i], photo: photos[i])
      end
      self.class.blank_slots.each do |pos|
        results[pos-1] = Slot.new(pos)
      end
      results
    end
  end

  def self.create_all(users, viewer, options = {})
    cards = users.map { |user| new(nil, viewer, user: user) }
    eager_fetch_associations(cards, options)
    cards
  end

  def self.eager_fetch_for_collection(cards, options = {})
    viewer_card = cards.detect(&:viewer)
    viewer = viewer_card.viewer if viewer_card
    eager_fetch_followings(cards, viewer)
    eager_fetch_listings_and_photos(cards, viewer)
    eager_fetch_listing_counts(cards, viewer)
    eager_fetch_collection_counts(cards, viewer)
    eager_fetch_like_counts(cards, viewer)
    eager_fetch_shared_interests(cards, viewer)
  end

  def self.eager_fetch_followings(cards, viewer)
    if viewer && cards.any?
      followings = viewer.following_follows_for(cards.map(&:user_id)).group_by(&:user_id)
      cards.each do |card|
        card.following = followings.fetch(card.user_id, []).any?
      end
    end
  end

  def self.eager_fetch_listings_and_photos(cards, viewer)
    if cards.any?
      policy = Users::RecentListingsQueuePolicy.new(count: listing_count)
      policy.choose!(cards.map(&:user))
      cards.each do |card|
        card.listings = policy.listings_for_user(card.user_id) || []
        card.photos = policy.photos_for_user(card.user_id) || []
      end
    end
  end

  def self.eager_fetch_listing_counts(cards, viewer)
    if cards.any?
      listing_counts = Listing.visible_counts(cards.map(&:user_id))
      cards.each do |card|
        card.listing_count = listing_counts.fetch(card.user_id, 0)
      end
    end
  end

  def self.eager_fetch_collection_counts(cards, viewer)
    if cards.any?
      collection_counts = User.collection_counts(cards.map(&:user_id))
      cards.each do |card|
        card.collection_count = collection_counts.fetch(card.user_id, 0)
      end
    end
  end

  def self.eager_fetch_like_counts(cards, viewer)
    if cards.any?
      like_counts = User.like_counts(cards.map(&:user_id))
      cards.each do |card|
        card.like_count = like_counts.fetch(card.user_id, 0)
      end
    end
  end

  def self.eager_fetch_shared_interests(cards, viewer)
    if viewer && cards.any?
      shared_interests = viewer.find_random_shared_interests(cards.map(&:user))
      cards.each do |card|
        card.shared_interest = shared_interests[card.user_id]
      end
    end
  end

  def self.listing_count
    @listing_count ||= config.listing_count || 0
  end

  def self.slot_count
    @slot_count ||= listing_count + blank_slots.size
  end

  def self.listing_slots
    @listing_slots ||= (1..slot_count).to_a - blank_slots
  end

  def self.blank_slots
    @blank_slots ||= config.blank_slots || []
  end

  def self.config
    Brooklyn::Application.config.users.card
  end
end
