class IndexTagObserver < ObserverBase
  include Brooklyn::ListingIndexable
  observe :tag

  def after_destroy_with_listings(tag, listings)
    listings.each { |l| upsert(l) }
  end

  def after_merge(tag, listing_ids)
    listing_ids.each { |id| upsert(id) }
  end

  def after_promote(tag, listings)
    listings.each { |l| upsert(l) }
  end
end
