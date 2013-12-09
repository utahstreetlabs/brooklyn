class InternalListing < Listing
  include InternalListings::Sync

  def supports_original_price?
    true
  end

  def supports_shipping?
    true
  end

  def supports_checkout?
    true
  end

  def supports_make_an_offer?
    true
  end

  def supports_recommend?
    true
  end

  def supports_dimensions?
    true
  end

  def supports_handling?
    true
  end

  # XXX: have to override the class-level accessors defined by Sluggable and Likeable since the way they define the
  # methods is not compatible with STI.

  def self.slug_field
    Listing.slug_field
  end

  def self.sluggable_field
    Listing.sluggable_field
  end

  def self.likeable_type
    :listing
  end

  def self.likeable_type_attr
    :listing_id
  end
end
