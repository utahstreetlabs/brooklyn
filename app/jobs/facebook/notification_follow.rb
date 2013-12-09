module Facebook
  class NotificationFollow < NotificationBase
    @queue = :facebook

    def self.work(follow_id)
      logger.debug("Posting notification to Facebook for follow #{follow_id}")
      with_error_handling("facebook notification follow", follow_id: follow_id) do
        follow = Follow.find(follow_id)
        notification_post(follow.follower, follow.user)
      end
    end

    def self.notification_post(follower, followee)
      follower_profile = follower.person.for_network(Network::Facebook.symbol)
      followee_profile = followee.person.for_network(Network::Facebook.symbol)
      return unless (follower_profile && followee_profile)
      # Do no inject a notification unless the follower and followee are also friends on Facebook.
      return unless followee_profile.followed_by?(follower_profile)
      begin
        params = {
          template: I18n.t('networks.facebook.notification.follow.template', user_id: follower_profile.uid),
          ref: Network::Facebook.notification_follow_group,
          href: profile_path(follower)
        }
        track_usage(Events::FbNotificationSent.new(fb_types: params[:ref]))
        followee_profile.post_notification(params)
      rescue Exception => e
        logger.warn("Unable to post follow to Facebook Notification API for user user_id=#{followee.id} uid=#{followee_profile.uid}", e)
      end
    end
  end
end
