module Notifications
  module Order
    class FailedExhibit < BaseExhibit
      if feature_enabled?('notifications.layout.v2')
        include Exhibitionist::RenderedWithCustom

        custom_render do |exhibit, viewer|
          role = exhibit.seller == viewer ? :seller_html : :buyer_html

          exhibit.render_notification(
            target: listing_url(exhibit.listing),
            body_text: nt(role, scope: [:order, :failed], listing: exhibit.listing.title),
            left_image: copious_logo_image_tag,
            right_image: listing_photo_tag(exhibit.listing.photos.first, :xsmall, class: 'notification-target-image')
          )
        end
      else
        include Exhibitionist::RenderedWithI18nString
      end

      # XXX Remove when the 'notifications.layout.v2' flag is enabled
      def i18n_key
        "text_html"
      end

      # XXX Remove when the 'notifications.layout.v2' flag is enabled
      def i18n_scope
        "exhibits.listings.orders.#{role}.failed"
      end
    end
  end
end
