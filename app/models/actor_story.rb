class ActorStory < Story
  decorates RisingTide::Story

  def complete?
    super && self.listing_ids.present? && self.listing_ids.any?
  end

  def actor
    unless defined?(@actor)
      @actor = User.where(id: self.actor_id).first
    end
  end

  def listings
    @listings ||= Listing.find_feed_displayable(self.listing_ids)
  end
end
