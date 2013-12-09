module Brooklyn
  module ListingIndexable

    def upsert(listing_or_id, *args)
      id = listing_or_id.is_a?(Listing) ? listing_or_id.id : listing_or_id
      if id
        Index::UpsertListing.enqueue(id)
      end
    end

    def remove(listing_or_id, *args)
      id = listing_or_id.is_a?(Listing) ? listing_or_id.id : listing_or_id
      if id
        Index::RemoveListing.enqueue(id)
      end
    end
  end
end
