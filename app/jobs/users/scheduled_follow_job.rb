require 'ladon'

module Users
  class ScheduledFollowJob < Ladon::Job
    include Brooklyn::MixpanelContext
    @queue = :autofollow

    def self.work(followee_id, follower_slug)
      with_error_handling("Scheduled follow of user #{followee_id} by #{follower_slug}", followee_id: followee_id,
                          follower_slug: follower_slug) do
        followee = User.where(id: followee_id).first!
        follower = User.where(slug: follower_slug).first!
        self.mixpanel_context = {skip_tracking: true}
        follower.follow!(followee, follow_type: AutomaticFollow)
      end
    end
  end
end
