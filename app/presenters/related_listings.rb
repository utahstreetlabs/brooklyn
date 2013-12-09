class RelatedListings
  include Enumerable
  include Ladon::Logging

  attr_reader :related
  delegate :each, to: :related

  def initialize(listing, options = {})
    @related = listing.related(options)
    @photo_cache = ListingPhoto.find_primaries(@related)
  end

  def photo_for(listing)
    @photo_cache[listing.id]
  end
end
