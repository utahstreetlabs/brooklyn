module Facebook
  class NotificationLikePost < NotificationBase
    @queue = :facebook

    def self.work(listing_id, profile_id, liker_profile_id)
      logger.debug("Posting notification like to Facebook to profile #{profile_id} for profile #{liker_profile_id}")
      with_error_handling("facebook notification like post", profile_id: profile_id) do
        listing = Listing.find(listing_id)
        profiles = Rubicon::FacebookProfile.find([profile_id, liker_profile_id])
        profile = profiles.select { |p| p.id == profile_id }.first
        liker_profile = profiles.select { |p| p.id == liker_profile_id }.first
        notification_post(listing, profile, liker_profile)
      end
    end

    # Notifications for likes/loves are posted to friends that have listed, loved, or
    # commented on the same listing.
    def self.notification_post(listing, profile, liker_profile)
      listing_title_length = Brooklyn::Application.config.networks.facebook.notification.listing_title_length
      params = {
        template: I18n.t('networks.facebook.notification.love.template', user_id: liker_profile.uid,
                         listing_title: listing.title.truncate(listing_title_length)),
        ref: Network::Facebook.notification_like_group,
        href: listing_path(listing)
      }
      begin
        track_usage(Events::FbNotificationSent.new(fb_types: params[:ref]))
        profile.post_notification(params)
      rescue Exception => e
        logger.warn("Unable to post like to Facebook Notification API for profile uid=#{profile.uid}", e)
      end
    end
  end
end
