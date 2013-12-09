class ListingListSnapshot
  include Brooklyn::RedisConnectable
  include Ladon::ErrorHandling

  attr_reader :timestamp, :key

  def initialize(slug, timestamp)
    @slug = slug
    @timestamp = timestamp
    @key = self.class.key_for_timestamp(@slug, @timestamp)
  end

  NILPROC = Proc.new { nil }

  def fetch_slice(offset, limit)
    self.class.with_error_handling('fetching snapshot from redis', retry_count: 1, additionally: NILPROC) do
      # lrange uses an inclusive right bound, so subtract 1
      self.class.redis.lrange(@key, offset, offset + limit - 1).map(&:to_i)
    end
  end

  def count
    self.class.with_error_handling('fetching snapshot count from redis', retry_count: 1, additionally: NILPROC) do
      self.class.redis.llen(@key)
    end
  end

  # @option options [Integer] timestamp of snapshot to use
  # @option options [Integer] page (1)
  # @option options [Integer] per
  def listings(options = {})
    page = [options[:page].to_i, 1].max
    limit = options.fetch(:per, 36).to_i
    offset = (page - 1) * limit
    ids = fetch_slice(offset, limit) || []
    listings = ids.any? ? Listing.where(id: ids).order_by_ids(ids) : ids
    # if there's an error, try to avoid a total_count less than what we already have
    total_count = count || (offset * limit + listings.count)
    Kaminari::PaginatableArray.new(listings, offset: offset, limit: limit, total_count: total_count)
  end

  def build!(listing_ids)
    # push from the right so the first entry is at position 0 and slicing makes sense
    self.class.redis.rpush(@key, listing_ids)
    self
  end

  # Store a snapshot of this listing list's state, along with a timestamp that can later be used to retrieve data
  # from the same snapshot
  def self.create!(slug, listing_ids)
    timestamp = Time.zone.now.to_i
    snapshot = new(slug, timestamp)
    snapshot.build!(listing_ids)
  end

  def self.find_for_timestamp(slug, timestamp)
    key = key_for_timestamp(slug, timestamp)
    unless timestamp.present? && redis.exists(key)
      timestamp = latest_timestamp(slug)
    end
    new(slug, timestamp)
  end

  def self.delete_old_keys!(slug, num_to_keep)
    times = sorted_timestamps(slug)
    to_delete = times[0...-num_to_keep].map { |t| key_for_timestamp(slug, t) }
    redis.del(*to_delete) if to_delete.any?
  end

  def self.key_for_timestamp(slug, timestamp)
    key = "#{slug}:#{timestamp}"
  end

  def self.timestamp_from_key(key)
    key.split(':').last.to_i
  end

  def self.keys(slug)
    redis.keys("#{slug}:*")
  end

  def self.sorted_timestamps(slug)
    keys(slug).map { |k| timestamp_from_key(k) }.sort
  end

  def self.latest_timestamp(slug)
    sorted_timestamps(slug).last
  end

  def self.latest_key(slug)
    key_for_timestamp(slug, latest_timestamp(slug))
  end

  def self.logger
    Rails.logger
  end
end
