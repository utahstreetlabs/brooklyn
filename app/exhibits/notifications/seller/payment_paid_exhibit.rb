module Notifications
  module Seller
    class PaymentPaidExhibit < BaseExhibit
      if feature_enabled?('notifications.layout.v2')
        include Exhibitionist::RenderedWithCustom

        custom_render do |exhibit, viewer|
          scope = [:seller, :payment_paid]
          scope << (exhibit.seller_payment.is_a?(PaypalPayment) ? :paypal : :bank)
          exhibit.render_notification(
            target: listing_url(exhibit.listing),
            body_text: nt(:self_html, scope: scope,
              listing: exhibit.listing.title, amount: smart_number_to_currency(exhibit.seller_payment.amount)),
            left_image: copious_logo_image_tag,
            right_image: listing_photo_tag(exhibit.listing.photos.first, :small)
          )
        end
      else
        include Exhibitionist::RenderedWithI18nString
      end

      def i18n_scope
        scope = "exhibits.notifications.seller.payment_paid"
        scope << (seller_payment.is_a?(PaypalPayment) ? '.paypal' : '.bank')
        scope
      end
    end
  end
end
