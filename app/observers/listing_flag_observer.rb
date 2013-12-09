class ListingFlagObserver < ObserverBase
  def after_create(flag)
    self.class.email_admin_listing_flagged(flag)
    self.class.notify_seller_listing_flagged(flag)
  end

  def self.email_admin_listing_flagged(flag)
    send_email(:create_notification, flag)
  end

  def self.notify_seller_listing_flagged(flag)
    inject_notification(:ListingFlagged, flag.listing.seller.id, listing_id: flag.listing.id)
  end
end
