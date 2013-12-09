class HotOrNotSuggestions
  include Ladon::Logging

  attr_reader :user, :listings, :photos

  def initialize(service, options = {})
    listing_count = options[:count] || 1
    @listings = service.suggestions.sample(listing_count)
    @photos = ListingPhoto.find_primaries(@listings)
    @user = service.user
  end
end
