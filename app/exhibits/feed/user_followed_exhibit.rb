module Feed
  class UserFollowedExhibit < Exhibitionist::Exhibit
    include Exhibitionist::RenderedWithHelper
    set_helper :follow_button

    def initialize(followee, viewer, context)
      super(followee, viewer, context)
    end

    def followee
      self
    end

    def follower
      viewer
    end

    def args
      options = {
        follower_count_selector: "#follower-count-#{followee.id}",
        follow_url: context.feed_user_follow_path(followee),
        unfollow_url: context.feed_user_unfollow_path(followee)
      }
      [followee, follower, options]
    end
  end
end
