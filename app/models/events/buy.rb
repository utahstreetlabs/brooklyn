module Events
  class Buy < Base
    set_event_name 'buy'

    def initialize(order)
      @properties = {listing_id: order.listing.id, order_id: order.id}
    end

    def self.complete_properties(props)
      listing_id = props.delete(:listing_id)
      props.merge(listing_properties(listing_id)).
        merge(listing_social_properties(listing_id)).
        merge(order_properties(props.delete(:order_id)))
    end
  end
end
