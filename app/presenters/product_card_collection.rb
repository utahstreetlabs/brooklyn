# Shared behavior for presenters that present lists of product cards.
module ProductCardCollection
  include Enumerable
  include Ladon::Logging

  attr_reader :user, :product_cards, :listings, :listing_idx, :photo_idx, :story_idx, :connection_idx
  delegate :each, to: :product_cards

  def objects
    @listings
  end

  def fetch_photos(listings)
    ListingPhoto.find_primaries(listings)
  end

  def eager_fetch_photos(options = {})
    @photo_idx = fetch_photos(listings)
    product_cards.each {|c| c.photo = photo_idx[c.listing.id]}
  end

  def eager_fetch_stories(options = {})
    product_cards.each { |c| c.story = ListingDefaultStory.new(c.listing.seller_id) }
  end

  def fetch_connections(user, listings)
    SocialConnection.all(user, listings.map {|l| l.seller})
  end

  def eager_fetch_likes(options = {})
    if product_cards.any?
      listing_ids = product_cards.map {|c| c.listing.id}
      existence_idx = user ? user.like_existences(:listing, listing_ids) : {}
      count_idx = Listing.like_counts(listing_ids)
      product_cards.each do |card|
        card.liked = existence_idx.fetch(card.listing.id, false)
        card.likes = count_idx.fetch(card.listing.id, 0)
      end
    end
  end

  def eager_fetch_saves(options = {})
    ProductCard.eager_fetch_saves(product_cards, user)
  end

  def eager_fetch_features(options = {})
    ProductCard.eager_fetch_features(product_cards, user)
  end

  def eager_fetch_latest_actors(options = {})
    ProductCard.eager_fetch_latest_actors(product_cards, options)
  end
end
