module Facebook
  class NotificationAnnouncePost < NotificationBase
    @queue = :facebook_announce

    def self.work(profile_id)
      logger.debug("Posting notification announcement to Facebook to profile #{profile_id}")
      with_error_handling("facebook notification announce post", profile_id: profile_id) do
        profile = Rubicon::FacebookProfile.find(profile_id, connection_count: true, onboarded_only: true)
        user = User.find_by_person_id!(profile.person_id)
        # We try to find the top two follower profiles.  Unfortunately because follows
        # are stored independently from profiles we need to execute a second query to get
        # them; thankfully we shouldn't be sending notifications to all users that often.
        # We can't just use the count of followers because we need their usernames for the
        # notification text....
        followers = profile.followers(limit: 2, rank: true, onboarded_only: true)
        notification_post(user, profile, followers)
      end
    end

    # Notifications for likes/loves are posted to friends that have listed, loved, or
    # commented on the same listing.
    def self.notification_post(user, profile, followers)
      # The number of follower profiles are used to customize the template.
      params = {
        ref: Network::Facebook.notification_announce_group,
        href: root_path
      }

      case profile.connection_count
      when 0
        params[:template] = I18n.t('networks.facebook.notification.announce.no_friends.template')
      when 1, 2
        params[:template] = I18n.t('networks.facebook.notification.announce.one_friend.template',
          user_id: followers[0].uid)
      else
        connection_count = (profile.connection_count - 2 > 2) ? 2 : 1
        other_friends = ActionController::Base.helpers.pluralize(connection_count, 'other friend')
        params[:template] = I18n.t('networks.facebook.notification.announce.many_friends.template',
          user_id_1: followers[0].uid, user_id_2: followers[1].uid, other_friends: other_friends)
      end

      begin
        track_usage(Events::FbNotificationSent.new(fb_types: params[:ref]))
        profile.post_notification(params)
      rescue Exception => e
        logger.warn("Unable to post like to Facebook Notification API for profile uid=#{profile.uid}", e)
      end
    end
  end
end
