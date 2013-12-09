module Events
  class UnsaveListing < ListingBase
    set_event_name 'unsave listing'

    def initialize(listing, collection, properties = {})
      super(listing, properties.merge(collection_id: collection.id))
    end

    def self.complete_properties(props)
      collection = Collection.find(props.delete(:collection_id))
      super(props).merge(collection_name: collection.slug, collection_creator: collection.user.slug,
                         collection_items: collection.listings.count)
    end
  end
end
