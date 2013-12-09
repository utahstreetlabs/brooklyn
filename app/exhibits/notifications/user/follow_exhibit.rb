module Notifications
  module User
    class FollowExhibit < BaseExhibit
      include Exhibitionist::RenderedWithCustom

      custom_render do |exhibit, viewer|
        exhibit.render_notification(
          target: followers_public_profile_url(viewer),
          body_text: nt(:self_html, scope: [:user, :follow], follower: exhibit.follower.name),
          left_image: user_avatar_small(exhibit.follower),
          right_image: user_avatar_small(viewer, class: 'notification-target-image')
        )
      end
    end
  end
end
