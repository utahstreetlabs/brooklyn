class TrendingList

  def self.create_snapshot!(window, limit)
    listing_ids = Listing.recently_liked(window, page: 1, per: limit)
    featured_ids = FeatureList.editors_picks.features.map(&:listing_id)
    trending_ids = listing_ids - featured_ids
    ListingListSnapshot.create!(prefix, trending_ids)
  end

  def self.truncate_snapshots!(limit)
    ListingListSnapshot.delete_old_keys!(prefix, limit)
  end

  def self.snapshot(timestamp = nil)
    ListingListSnapshot.find_for_timestamp(prefix, timestamp)
  end

  def self.prefix
    'trending:snapshot'
  end
end
