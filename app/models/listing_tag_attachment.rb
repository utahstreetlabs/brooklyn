class ListingTagAttachment < ActiveRecord::Base
  belongs_to :listing
  belongs_to :tag

  # note that we don't use callbacks to reindex the listing when a tag is attached or detached to it because
  # probably multiple tags are being attached or detached at the same time. it's the caller's responsibility to
  # ensure that the listings are reindexed.

  # Returns a hash of attached listing counts by tag id.
  def self.listing_counts(tags = nil)
    q = select('COUNT(*) AS listing_count, tag_id')
    if tags
      tag_ids = Array.wrap(tags).compact.inject([]) { |m, t| m.concat(t.subtags.map(&:id)); m << t.id; m }
      q = q.where(tag_id: tag_ids) if tag_ids.any?
    end
    q.group('tag_id').all.inject({}) do |rv, result|
      rv[result.tag_id] = result.listing_count
      rv
    end
  end
end
