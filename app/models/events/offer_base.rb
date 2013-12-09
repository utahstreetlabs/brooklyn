module Events
  class OfferBase < Base
    include OfferProperties

    def initialize(offer, properties = {})
      @properties = {offer_id: offer.id}.merge(properties)
    end

    def self.complete_properties(props)
      props.merge(offer_properties(props.delete(:offer_id)))
    end
  end
end
