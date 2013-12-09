require 'ladon'

module Facebook
  class OpenGraphFollow < OpenGraphJob
    @queue = :facebook

    def self.work(follow_id)
      logger.debug("Posting follow to Facebook for follow #{follow_id}")
      with_error_handling("facebook open graph follow", follow_id: follow_id) do
        follow = Follow.find(follow_id)
        subscription = open_graph_post(follow.follower, follow.user)
        follow.update_attribute(:fb_subscription_id, subscription.id) if subscription
      end
    end

    # If the followee has a known facebook profile, we pass its uid along as
    # the "profile." If not, we pass the URL of their Copious profile, and
    # Facebook will scrape this much as they have in the past.
    #
    # Note that we could consolidate on always passing the public profile url if we
    # were willing to ad facebook third_party_ids to rubicon and include them in public
    # profile pages but I think that's something we should hold off on.
    #
    # @see https://developers.facebook.com/docs/opengraph/actions/builtin/follows/
    def self.fb_og_profile(user)
      profile = user.person.for_network(:facebook)
      if profile
        profile.uid
      else
        url_helpers.public_profile_url(user)
      end
    end

    # Post that an action, such as a follow, that user took on the target_url for the object
    def self.open_graph_post(follower, followee)
      fb_profile_id = fb_og_profile(followee)
      profile = follower.person.for_network(:facebook)
      if profile && profile.og_postable?
        logger.debug("Posting follow for user id #{follower.id} to Facebook open graph, profile = #{fb_profile_id}")
        begin
          track_action(follower, :user, :follow) do
            props = {ns: :og, profile: fb_profile_id, fb_ref: "profile:follow",
              fb_ref_data: fb_ref_data(follower, followee, fb_profile_id)}
            profile.post_to_ticker(open_graph_props(:follows, props))
          end
        rescue Exception => e
          logger.warn("Unable to post follow to Facebook Open Graph in OpenGraphFollow job for user user_id=#{follower.id} uid=#{profile.uid}", e)
        end
      end
    end

    def self.fb_ref_data(follower, followee, fb_profile)
      fb_ref_user_data(follower).merge(followee_slug: followee.slug, fb_profile: fb_profile)
    end
  end
end
