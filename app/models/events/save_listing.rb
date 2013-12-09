module Events
  class SaveListing < ListingBase
    set_event_name 'save listing'

    def initialize(listing, collection, price_alert, properties = {})
      p = properties.merge(collection_id: collection.id)
      p[:price_alert_id] = price_alert.id if price_alert
      super(listing, p)
    end

    def self.complete_properties(props)
      collection = Collection.find(props.delete(:collection_id))
      p = {
        collection_name: collection.slug,
        collection_creator: collection.user.slug,
        collection_items: collection.listings.count
      }
      if props.key?(:price_alert_id)
        price_alert = PriceAlert.find(props.delete(:price_alert_id))
        p[:price_alert] = if price_alert.threshold == 0
          'all'
        else
          price_alert.threshold
        end
      else
        p[:price_alert] = 'none'
      end
      super(props).merge(p)
    end
  end
end
