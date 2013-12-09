module Events
  class WantItem < Base
    set_event_name 'want item'

    def initialize(want, properties = {})
      @properties = properties.merge(want_id: want.id)
    end

    def self.complete_properties(props)
      want = Want.find(props.delete(:want_id))
      # assumes that items can't be re-listed. revisit when that is no longer true.
      listing = want.item.listings.first
      props = props.merge(listing_properties(listing.id))
      props = props.merge(order_properties(listing.order.id)) if listing.order
      props[:user_name] = want.user.slug
      props[:want_price] = want.max_price
      props[:want_condition] = want.condition
      props
    end
  end
end
