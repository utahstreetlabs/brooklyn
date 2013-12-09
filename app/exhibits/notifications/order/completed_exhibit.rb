module Notifications
  module Order
    class CompletedExhibit < BaseExhibit
      if feature_enabled?('notifications.layout.v2')
        include Exhibitionist::RenderedWithCustom

        custom_render do |exhibit, viewer|
          if exhibit.seller == viewer
            role = :self_html
            target = listing_url(exhibit.listing)
          else
            role = :user_html
            target = public_profile_url(exhibit.seller)
          end

          exhibit.render_notification(
            target: target,
            body_text: nt(role, scope: [:order, :completed],
              listing: exhibit.listing.title, seller: exhibit.seller.name),
            left_image: copious_logo_image_tag,
            right_image: listing_photo_tag(exhibit.listing.photos.first, :xsmall, class: 'notification-target-image')
          )
        end
      else
        include Exhibitionist::RenderedWithPartial
        set_partial '/notifications/order_completed'
      end
    end
  end
end
