class CollectionCard
  include Ladon::Logging

  attr_reader :collection, :viewer
  attr_accessor :owner, :photos, :listing_count, :following, :follower_count
  delegate :name, to: :collection

  def initialize(collection, viewer, options = {})
    @collection = collection
    @viewer = viewer
    @photos = options.fetch(:photos, [])
    @listing_count = options.fetch(:listing_count, 0)
    @following = options.fetch(:following, false)
  end

  def complete?
    collection && owner && listing_count
  end

  def logger
    self.class.logger
  end

  def self.eager_fetch_associations(cards, options = {})
    eager_fetch_owners(cards, options)
    eager_fetch_photos(cards, options)
    eager_fetch_listing_counts(cards, options)
    eager_fetch_followings(cards, options)
    eager_fetch_follower_count(cards, options)
  end

  # @option options [User] owner if provided, used as the owner for all cards
  def self.eager_fetch_owners(cards, options = {})
    if cards.any?
      if options[:owner]
        cards.each { |card| card.owner = options[:owner] }
      else
        owner_ids = cards.map { |c| c.collection.user_id }.uniq
        owner_idx = User.find_registered_users(id: owner_ids).group_by(&:id)
        cards.each do |card|
          card.owner = owner_idx[card.collection.user_id].first
        end
      end
    end
  end

  def self.eager_fetch_photos(cards, options = {})
    if cards.any?
      collections = cards.map(&:collection)
      listing_idx = Collection.recently_added_visible_listings(collections, ids_only: true, limit: listings_per_card)
      all_listing_ids = cards.map { |card| listing_idx[card.collection.id] }.flatten
      photo_idx = ListingPhoto.find_primaries(all_listing_ids)
      cards.each do |card|
        listing_ids = listing_idx[card.collection.id]
        if listing_ids.any?
          card.photos = listing_ids.map { |id| photo_idx[id] }.compact
        end
      end
    end
  end

  def self.eager_fetch_listing_counts(cards, options)
    if cards.any?
      collection_ids = cards.map { |c| c.collection.id }.uniq
      counts = Collection.visible_counts(collection_ids)
      cards.each do |card|
        card.listing_count = counts.fetch(card.collection.id, 0)
      end
    end
  end

  def self.eager_fetch_followings(cards, options)
    if cards.any? && cards.first.viewer
      collection_ids = cards.map { |c| c.collection.id }.uniq
      counts = cards.first.viewer.collection_followings(collection_ids)
      cards.each do |card|
        card.following = counts.fetch(card.collection.id, false)
      end
    end
  end

  def self.eager_fetch_follower_count(cards, options)
    if cards.any?
      collection_ids = cards.map { |c| c.collection.id }.uniq
      counts = CollectionFollow.counts_for_collections(collection_ids)
      cards.each do |card|
        card.follower_count = counts.fetch(card.collection.id, 0)
      end
    end
  end

  def self.listings_per_card
    config.listing_count
  end

  def self.config
    Brooklyn::Application.config.collections.card
  end

  def self.logger
    Rails.logger
  end
end
