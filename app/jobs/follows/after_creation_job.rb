require 'autoshare/user_followed'
require 'brooklyn/redhook'
require 'brooklyn/sprayer'
require 'facebook/open_graph_user'
require 'ladon'

module Follows
  class AfterCreationJob < Ladon::Job
    include Brooklyn::Sprayer

    @queue = :follows

    class << self
      # @options options [Boolean] :notify_followee should the followee be notified of this follow?
      # @options options [Boolean] :suppress_fb_follow should facebook follows be suppressed?
      def work(id, options = {})
        with_error_handling("After creation of follow #{id} with options #{options}", options.merge(follow_id: id)) do
          follow = Follow.where(id: id).first
          if follow
            send_user_follow_email(follow, options)
            inject_user_follow_notification(follow, options)
            autoshare_user_follow(follow)
            # create_connection(follow)
            post_user_follow_to_facebook(follow, options)
            post_follow_notification_to_facebook(follow, options)
            update_mixpanel(follow)
            track_usage(Events::FollowUser.new(follow))
          else
            logger.debug("Follow #{id} disappeared, skipping after creation job")
          end
        end
      end

      def send_user_follow_email(follow, options = {})
        return if follow.refollow? && !options.fetch(:refollow, false)
        return if follow.follower.directly_invited_by?(follow.followee)
        send_email(:follow, follow) if follow.followee.allow_email?(:follow_me) && options[:notify_followee]
      end

      def inject_user_follow_notification(follow, options = {})
        unless follow.refollow?
          inject_notification(:Follow, follow.user_id, follower_id: follow.follower_id) if options[:notify_followee]
        end
      end

      def autoshare_user_follow(follow)
        unless follow.refollow?
          Autoshare::UserFollowed.enqueue(follow.user_id, profile_url(follow.followee), follow.follower_id)
        end
      end

      def create_connection(follow)
        Brooklyn::Redhook.async_create_connection(follow.follower.person_id, follow.followee.person_id, :usl_follower)
      end

      def post_user_follow_to_facebook(follow, options = {})
        follow.post_to_facebook! unless options[:suppress_fb_follow]
      end

      def post_follow_notification_to_facebook(follow, options = {})
        follow.post_notification_to_facebook! if options[:notify_followee]
      end

      def profile_url(user)
        url_helpers.public_profile_url(user)
      end

      def update_mixpanel(follow)
        follow.follower.mixpanel_increment!(:follows)
      end
    end
  end
end
