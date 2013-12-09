class ListingCollectionAttachment < ActiveRecord::Base
  belongs_to :collection, counter_cache: :listing_count
  belongs_to :listing
  attr_accessible :listing_id, :collection_id

  after_commit on: :create do
    ListingCollectionAttachments::AfterCreatedJob.enqueue(self.id)
  end

  after_destroy do
    ListingCollectionAttachments::AfterDestroyedJob.enqueue(self.id)
  end

  def self.listing_counts(listing_ids)
    where(listing_id: listing_ids).count(group: :listing_id)
  end
end
