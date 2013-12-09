module Notifications
  module Listing
    class RepliedExhibit < BaseExhibit
      if feature_enabled?('notifications.layout.v2')
        include Exhibitionist::RenderedWithCustom

        custom_render do |exhibit, viewer|
          exhibit.render_notification(
            target: listing_url(exhibit.listing),
            body_text: nt(:self_html, scope: [:listing, :replied],
              listing: exhibit.listing.title, replier: exhibit.replier.name),
            left_image: user_avatar_small(exhibit.replier),
            right_image: listing_photo_tag(exhibit.listing.photos.first, :xsmall, class: 'notification-target-image')
          )
        end
      else
        include Exhibitionist::RenderedWithI18nString
      end

      def i18n_scope
        "exhibits.notifications.listing.replied"
      end

      def i18n_params
        {listing_link: context.link_to_listing(listing), replier_link: context.link_to_user_profile(replier)}
      end
    end
  end
end
