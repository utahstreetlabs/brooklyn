class ListingResults
  include Ladon::Logging
  include ProductCardCollection

  def initialize(user, listings, options = {})
    @user = user
    @product_cards = listings.map {|l| ProductCard.new(nil, user, listing: l, collection: options[:collection])}
    @listings = listings
    @listing_idx = listings.inject({}) {|m, l| m.merge!(l.id => l)}
    eager_fetch_photos(options)
    # already have listing info for each story, so don't load it again
    eager_fetch_stories(options.merge(no_listings: true))
    eager_fetch_likes(options)
    eager_fetch_saves(options)
    eager_fetch_latest_actors(options)
    eager_fetch_features(options)
  end
end
