class IndexListingObserver < ObserverBase
  include Brooklyn::ListingIndexable
  observe :internal_listing, :external_listing

  IGNORE_IN_INDEX = [:seller_pays_marketplace_fee, :source_uid, :created_at, :updated_at]

  alias_method :after_tag_add, :upsert
  alias_method :after_tag_remove, :upsert
  alias_method :after_dimension_value_add, :upsert
  alias_method :after_dimension_value_remove, :upsert
  alias_method :after_like, :upsert
  alias_method :after_unlike, :upsert
  # use this instead of after_save so the resque job is guaranteed to see the listing in the new state
  alias_method :after_commit, :upsert

  alias_method :after_cancel, :remove
  alias_method :after_suspend, :remove
end
