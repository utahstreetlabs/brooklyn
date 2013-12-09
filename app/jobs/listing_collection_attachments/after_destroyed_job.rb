module ListingCollectionAttachments
  class AfterDestroyedJob < Ladon::Job
    @queue = :collections

    def self.work(id)
      with_error_handling("After listing collection attachment #{id} destroyed",
                          listing_collection_attachment_id: id) do
        lca = ListingCollectionAttachment.find(id)
        evict_listing_from_recent_cache(lca.listing)
      end
    end

    def self.evict_listing_from_recent_cache(listing)
      listing.seller.recent_saved_listing_ids.delete(listing.id)
    end
  end
end
