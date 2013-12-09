module Events
  class HaveItem < Base
    set_event_name 'have item'

    def initialize(have, properties = {})
      @properties = properties.merge(have_id: have.id)
    end

    def self.complete_properties(props)
      have = Have.find(props.delete(:have_id))
      # assumes that items can't be re-listed. revisit when that is no longer true.
      listing = have.item.listings.first
      props = props.merge(listing_properties(listing.id))
      props = props.merge(order_properties(listing.order.id)) if listing.order
      props[:user_name] = have.user.slug
      props
    end
  end
end
