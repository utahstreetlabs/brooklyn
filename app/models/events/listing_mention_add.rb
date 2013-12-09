module Events
  class ListingMentionAdd < ListingBase
    set_event_name 'listing_mention add'

    def initialize(listing, mentioner, mentionee, properties = {})
      properties[:mentioner] = mentioner.slug
      properties[:mentionee] = mentionee.slug if mentionee
      super(listing, properties)
    end
  end
end
