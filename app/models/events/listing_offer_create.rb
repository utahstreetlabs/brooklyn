module Events
  class ListingOfferCreate < ListingBase
    set_event_name 'make_offer complete'

    def initialize(offer, properties = {})
      super(offer.listing, properties.merge(listing_offer_id: offer.id))
    end

    def self.complete_properties(props)
      offer = ListingOffer.find(props.delete(:listing_offer_id))
      super(props).merge(offerer: offer.user.slug, offer_value: offer.amount, offer_created_at: offer.created_at)
    end
  end
end
