module Events
  class RedirectExternalListing < ListingBase
    set_event_name 'external_listing redirect'

    def initialize(listing, properties = {})
      clicker = properties.delete(:clicker)
      properties[:clicked_by] = clicker.slug if clicker
      super(listing, properties)
    end
  end
end
