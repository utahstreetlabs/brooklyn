module Notifications
  module Listing
    class LikeExhibit < BaseExhibit
      if feature_enabled?('notifications.layout.v2')
        include Exhibitionist::RenderedWithCustom

        custom_render do |exhibit, viewer|
          seller_role = (exhibit.seller == viewer ? :seller_self : :seller_user)
          role = (exhibit.liker == viewer ? :self_html : :user_html)

          exhibit.render_notification(
            target: listing_url(exhibit.listing),
            body_text: nt(role, scope: [:listing, :like, seller_role],
              listing: exhibit.listing.title, liker: exhibit.liker.name),
            left_image: user_avatar_small(exhibit.liker),
            right_image: listing_photo_tag(exhibit.listing.photos.first, :xsmall, class: 'notification-target-image')
          )
        end
      else
        include Exhibitionist::RenderedWithPartial
        set_partial '/notifications/listing_like'
      end
    end
  end
end
