module Events
  class ListingBase < Base
    def initialize(listing, properties = {})
      @properties = {listing_id: listing.id}.merge(properties)
    end

    def self.complete_properties(props)
      listing_id = props.delete(:listing_id)
      props.merge(listing_properties(listing_id)).
        merge(listing_social_properties(listing_id))
    end
  end
end
