module ListingCollectionAttachments
  class AfterCreatedJob < Ladon::Job
    include Brooklyn::Sprayer

    @queue = :collections

    def self.work(id)
      with_error_handling("After listing collection attachment #{id} created",
                          listing_collection_attachment_id: id) do
        lca = ListingCollectionAttachment.find(id)
        inject_listing_save_notification(lca.listing, lca.collection)
        send_listing_save_email(lca.listing, lca.collection)
        add_listing_to_recent_cache(lca.listing)
        update_mixpanel(lca.listing, lca.collection)
      end
    end

    def self.inject_listing_save_notification(listing, collection)
      unless collection.owned_by?(listing.seller)
        inject_notification(:ListingSave, listing.seller_id, collection_id: collection.id, saver_id: collection.user_id,
                            listing_id: listing.id)
      end
    end

    def self.send_listing_save_email(listing, collection)
      unless collection.owned_by?(listing.seller)
        send_email(:saved, listing, collection.id) if listing.seller.allow_email?(:listing_save)
      end
    end

    def self.add_listing_to_recent_cache(listing)
      unless listing.seller.recent_saved_listing_ids.include?(listing.id)
        listing.seller.recent_saved_listing_ids << listing.id
      end
    end

    def self.update_mixpanel(listing, collection)
      # assumes only the collection owner can save a listing to the collection
      price_alert = collection.owner.price_alert_for(listing)
      track_usage(Events::SaveListing.new(listing, collection, price_alert))
    end
  end
end
