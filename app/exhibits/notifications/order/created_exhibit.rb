module Notifications
  module Order
    class CreatedExhibit < BaseExhibit
      if feature_enabled?('notifications.layout.v2')
        include Exhibitionist::RenderedWithCustom

        custom_render do |exhibit, viewer|
          exhibit.render_notification(
            target: listing_url(exhibit.listing),
            body_text: nt(:buyer_html, scope: [:order, :created],
              listing: exhibit.listing.title, user: exhibit.buyer.name),
            left_image: user_avatar_small(exhibit.buyer),
            right_image: listing_photo_tag(exhibit.listing.photos.first, :xsmall, class: 'notification-target-image')
          )
        end
      else
        include Exhibitionist::RenderedWithPartial
        set_partial '/notifications/order_created'
      end
    end
  end
end
