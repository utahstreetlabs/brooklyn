module Notifications
  module Invite
    class SentPileOnExhibit < BaseExhibit
      if feature_enabled?('notifications.layout.v2')
        include Exhibitionist::RenderedWithCustom

        custom_render do |exhibit, viewer|
          role = exhibit.inviter == viewer ? :self_html : :user_html

          exhibit.render_notification(
            target: public_profile_url(exhibit.inviter),
            body_text: nt(role, scope: [:invite, :sent_pile_on],
              inviter: exhibit.inviter.name, invitee: exhibit.invitee_profile.name,
              network: t(:name, scope: "networks.#{exhibit.invitee_profile.network}")),
            left_image: user_avatar_small(viewer),
            right_image: user_avatar_small(exhibit.inviter)
          )
        end
      else
        include Exhibitionist::RenderedWithPartial
        set_partial '/notifications/invite_sent_pileon'
      end
    end
  end
end
