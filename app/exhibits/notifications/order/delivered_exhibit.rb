module Notifications
  module Order
    class DeliveredExhibit < BaseExhibit
      if feature_enabled?('notifications.layout.v2')
        include Exhibitionist::RenderedWithCustom

        custom_render do |exhibit, viewer|
          if exhibit.seller == viewer
            role = :seller_html
            user = exhibit.buyer
          else
            role = :buyer_html
            user = exhibit.seller
          end

          exhibit.render_notification(
            target: listing_url(exhibit.listing),
            body_text: nt(role, scope: [:order, :delivered],
              listing: exhibit.listing.title, user: user.name),
            left_image: copious_logo_image_tag,
            right_image: listing_photo_tag(exhibit.listing.photos.first, :xsmall, class: 'notification-target-image')
          )
        end
      else
        include Exhibitionist::RenderedWithPartial
        set_partial '/notifications/order_delivered'
      end
    end
  end
end
