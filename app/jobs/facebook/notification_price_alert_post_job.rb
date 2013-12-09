module Facebook
  class NotificationPriceAlertPostJob < NotificationBase
    @queue = :facebook_announce

    def self.work(profile_id)
      logger.debug("Posting price alert notification to Facebook profile ##{profile_id}")
      with_error_handling("Post Facebook price alert notification", profile_id: profile_id) do
        profile = Rubicon::FacebookProfile.find(profile_id, onboarded_only: true)
        user = User.find_by_person_id!(profile.person_id)
        discount = compute_discount
        listing = find_interacted_with_listing(user)
        if listing
          variant = "b"
        else
          listing = find_trending_listing(user)
          variant = "a"
        end
        if listing
          ref = compute_ref(discount, variant)
          track_send(ref)
          post_notification(profile, listing, discount, ref)
        else
          logger.warn("No trending listings; skipping price alert notification")
        end
      end
    end

    def self.compute_discount
      PriceAlert::Discounts.random
    end

    # Returns a randomly chosen listing from the set of listings that +user+ has liked and/or saved. Prefers saved
    # over liked.
    def self.find_interacted_with_listing(user)
      limit = max = Network::Facebook.config.notification.price_alert.interacted_with_listing_choices
      listing_ids = Listing.recently_saved_by_ids(user, limit: limit, exclude_sellers: user)
      if listing_ids.size < max
        limit = max - listing_ids.size
        listing_ids += Listing.liked_by_ids(user, page: 1, per: limit, exact_order: true, exclude_sellers: user)
      end
      Listing.visible(listing_ids.sample).first
    end

    # Returns a randomly chosen listing from the most trending listings.
    def self.find_trending_listing(user)
      window = Network::Facebook.config.notification.price_alert.random_trending_window
      limit = Network::Facebook.config.notification.price_alert.random_trending_listing_choices
      listing_ids = Listing.find_trending_ids(window, page: 1, per: limit, exclude_sellers: user)
      Listing.visible(listing_ids.sample).first
    end

    def self.compute_ref(discount, variant)
      "#{Network::Facebook.config.notification.price_alert.ref_prefix}_#{discount}_#{variant}"
    end

    def self.track_send(ref)
      track_usage(Events::FbNotificationSent.new(fb_types: ref))
    end

    def self.post_notification(profile, listing, discount, ref)
      title_max_length = Network::Facebook.config.notification.price_alert.title_max_length
      profile.post_notification(
        ref: ref,
        href: listing_path(listing, src: 'pa'), # lets us know the user clicked from a price alert notification
        template: I18n.t('networks.facebook.notification.price_alert.template',
                         listing_title: view_context.truncate(listing.title, length: title_max_length),
                         discount: discount)
      )
    end
  end
end
