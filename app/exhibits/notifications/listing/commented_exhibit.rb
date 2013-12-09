module Notifications
  module Listing
    class CommentedExhibit < BaseExhibit
      if feature_enabled?('notifications.layout.v2')
        include Exhibitionist::RenderedWithCustom

        custom_render do |exhibit, viewer|
          seller_role = (exhibit.seller == viewer ? :seller_self : :seller_user)
          role = (exhibit.commenter == viewer ? :self_html : :user_html)

          exhibit.render_notification(
            target: listing_url(exhibit.listing),
            body_text: nt(role, scope: [:listing, :commented, seller_role],
              listing: exhibit.listing.title, commenter: exhibit.commenter.name),
            left_image: user_avatar_small(exhibit.commenter),
            right_image: listing_photo_tag(exhibit.listing.photos.first, :xsmall, class: 'notification-target-image')
          )
        end
      else
        include Exhibitionist::RenderedWithI18nString
      end

      # XXX Remove when the 'notifications.layout.v2' flag is enabled
      def i18n_scope
        "exhibits.notifications.listing.commented"
      end

      # XXX Remove when the 'notifications.layout.v2' flag is enabled
      def i18n_params
        {listing_link: context.link_to_listing(listing), commenter_link: context.link_to_user_profile(commenter)}
      end
    end
  end
end
