module Events
  class ListingHashtagAdd < ListingBase
    set_event_name 'listing_hashtag add'

    def initialize(listing, tag, properties = {})
      super(listing, properties.merge(tag: tag.slug))
    end
  end
end
