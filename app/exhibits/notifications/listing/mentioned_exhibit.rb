module Notifications
  module Listing
    class MentionedExhibit < BaseExhibit
      if feature_enabled?('notifications.layout.v2')
        include Exhibitionist::RenderedWithCustom

        custom_render do |exhibit, viewer|
          exhibit.render_notification(
            target: listing_url(exhibit.listing),
            body_text: nt(:user_html, scope: [:listing, :mentioned],
              listing: exhibit.listing.title, commenter: exhibit.commenter.name),
            left_image: user_avatar_small(exhibit.commenter),
            right_image: user_avatar_small(viewer, class: 'notification-target-image')
          )
        end
      else
        include Exhibitionist::RenderedWithI18nString
      end

      # XXX Remove when the 'notifications.layout.v2' flag is enabled
      def i18n_scope
        "exhibits.notifications.listing.mentioned"
      end

      # XXX Remove when the 'notifications.layout.v2' flag is enabled
      def i18n_params
        {commenter_link: context.link_to_user_profile(commenter),
          listing_link: context.link_to_listing(listing, class: 'mention-notification-link',
            data: {mentionee_slug: viewer.slug, mentioner_slug: commenter.slug})}
      end
    end
  end
end
