class FeatureList < ActiveRecord::Base
  include Sluggable
  include Featurable

  has_slug :slug
  features_listings order_by_position: false

  has_many :listings, through: :features

  default_sort_column :name
  search_columns :name

  attr_accessible :name, :slug

  # Returns listings from this list within a window of time
  #
  # @param [ActiveSupport::TimeWithZone] from_time the earliest time a matching feature was created
  # @param [ActiveSupport::TimeWithZone] to_time the latest time a matching feature was created
  #
  # @return [Array]
  def find_listings_in_window(from_time, to_time)
    logger.debug("Finding listings on #{name} list featured between #{from_time} and #{to_time}")
    features.where("#{ListingFeature.quoted_table_name}.created_at BETWEEN ? AND ?", from_time, to_time).
      includes(:listing).map(&:listing)
  end

  # Returns the most recently featured listings from this list
  #
  # @param [Integer] limit Maximum number of listings to return
  #
  # @return [Array]
  def find_recent_listings(limit)
    features.order("#{ListingFeature.quoted_table_name}.created_at DESC").limit(limit).
      includes(:listing).map(&:listing)
  end

  def create_snapshot!(window, limit)
    listing_ids = find_recent_listings(limit).map(&:id)
    ordered = Listing.recently_liked(window, listing_ids: listing_ids, batch_size: self.class.batch_size)
    # re-insert anything that didn't have any likes
    ordered = ordered.concat(listing_ids - ordered)
    ListingListSnapshot.create!(prefixed_slug, ordered)
  end

  def truncate_snapshots!(limit)
    ListingListSnapshot.delete_old_keys!(prefixed_slug, limit)
  end

  def snapshot(timestamp = nil)
    ListingListSnapshot.find_for_timestamp(prefixed_slug, timestamp)
  end

  def prefixed_slug
    "featurable:snapshot:#{slug}"
  end

  # Returns an array of feature lists corresponding to the provided names.
  # @see #find_or_create_by_name(name)
  def self.find_or_create_all_by_name(names = [])
    Array(names).map {|n| find_or_create_by_name(n)}.uniq
  end

  # Returns a feature list corresponding to the provided name.
  # The feature list is created if one with that name does not already exist.
  def self.find_or_create_by_name(name, other_attrs = {})
    feature_list = find_by_slug(FeatureList.compute_slug(name)) || new(other_attrs.merge(name: name))
    feature_list.save! if feature_list.new_record?
    feature_list
  end

  def self.editors_picks
    @editors_picks ||= find_by_slug!('editors-picks')
  end

  def self.batch_size
    Brooklyn::Application.config.home.featured.batch_size
  end
end
