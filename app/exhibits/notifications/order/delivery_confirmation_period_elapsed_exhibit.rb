module Notifications
  module Order
    class DeliveryConfirmationPeriodElapsedExhibit < BaseExhibit
      if feature_enabled?('notifications.layout.v2')
        include Exhibitionist::RenderedWithCustom

        custom_render do |exhibit, viewer|
          role = exhibit.seller == viewer ? :seller_html : :buyer_html
          exhibit.render_notification(
            target: listing_url(exhibit.listing),
            body_text: nt(role, scope: [:order, :delivery_confirmation_period_elapsed],
              listing: exhibit.listing.title, buyer: exhibit.buyer.name),
            left_image: copious_logo_image_tag,
            right_image: listing_photo_tag(exhibit.listing.photos.first, :xsmall, class: 'notification-target-image')
          )
        end
      else
        include Exhibitionist::RenderedWithI18nString
      end

      # XXX Remove when the 'notifications.layout.v2' flag is enabled
      def i18n_scope
        "exhibits.notifications.order.delivery_confirmation_period_elapsed.#{role}"
      end

      # XXX Remove when the 'notifications.layout.v2' flag is enabled
      def i18n_params
        p = super
        p[:buyer_link] = context.link_to_user_profile(buyer) if seller?
        p
      end
    end
  end
end
