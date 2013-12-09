module Notifications
  module Order
    class ShippedExhibit < BaseExhibit
      if feature_enabled?('notifications.layout.v2')
        include Exhibitionist::RenderedWithCustom

        custom_render do |exhibit, viewer|
          exhibit.render_notification(
            target: listing_url(exhibit.listing),
            body_text: nt(:buyer_html, scope: [:order, :shipped],
              listing: exhibit.listing.title, user: exhibit.seller.name),
            left_image: copious_logo_image_tag,
            right_image: listing_photo_tag(exhibit.listing.photos.first, :xsmall, class: 'notification-target-image')
          )
        end
      else
        include Exhibitionist::RenderedWithPartial
        set_partial '/notifications/order_shipped'
      end
    end
  end
end
