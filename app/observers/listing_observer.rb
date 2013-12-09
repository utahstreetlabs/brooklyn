class ListingObserver < ObserverBase
  observe :internal_listing, :external_listing

  def after_comment_flagged(listing, comment, flag)
    email_comment_flagged_for_admin(listing, comment, flag)
  end

  def after_feature(listing)
    email_featured(listing)
    add_listing_to_recent_cache(listing, listing.seller)
  end

  def after_share(listing, sharer, network)
    unless sharer == listing.seller
      activitize_shared(listing, sharer, network)
      email_shared(listing, sharer, network)
      add_listing_to_recent_cache(listing, sharer)
    end
  end

  def after_comment(listing, commenter, comment, options = {})
    unless commenter == listing.seller
      add_listing_to_recent_cache(listing, commenter)
    end
    commenter.mark_commenter!
    Listings::AfterCommentedJob.enqueue(listing.id, commenter.id, comment.id, options)
  end

  def after_like(listing, liker, like, options = {})
    track!(:listing_liked)
    liker.mixpanel_increment!(:likes)
    unless liker == listing.seller or like.tombstone
      add_listing_to_recent_cache(listing, liker)
    end
    Listings::AfterLikeJob.enqueue(listing.id, liker.id, like.id, options)
  end

  def after_unlike(listing, unliker, options = {})
    evict_listing_from_recent_cache(listing, unliker)
  end

  def email_comment_flagged_for_admin(listing, comment, flag)
    self.class.send_email(:comment_flagged_for_admin, listing, comment.id, flag.serializable_hash)
  end

  def email_featured(listing)
    self.class.send_email(:featured, listing) if listing.seller.allow_email?(:listing_feature)
  end

  def email_shared(listing, sharer, network)
    network = network.to_sym
    if [:twitter, :facebook].include?(network) and listing.seller.allow_email?("listing_share_#{network}".to_sym)
      self.class.send_email(:shared, listing, sharer.id, network)
    end
  end

  def activitize_shared(listing, sharer, network)
    self.class.inject_listing_story(:listing_shared, sharer.id, listing, network: network)
  end

  def add_listing_to_recent_cache(listing, user)
    user.recent_listing_ids << listing.id unless user.recent_listing_ids.include?(listing.id)
  end

  def evict_listing_from_recent_cache(listing, user)
    user.recent_listing_ids.delete(listing.id)
  end
end
