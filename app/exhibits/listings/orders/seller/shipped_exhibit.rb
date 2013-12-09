module Listings
  module Orders
    module Seller
      class ShippedExhibit < Listings::Orders::SellerExhibit
        include Exhibitionist::RenderedWithCustom

        custom_render do |listing, viewer|
          content_tag(:div, class: 'top-text-section') do
            content_tag(:h2, class: 'inline') do
              out = []
              out << t('.header_html')
              out << tag(:br)
              out << t('.delivery_info_html', carrier: listing.order.shipping_carrier_name,
                       tracking_number: listing.order.tracking_number)
              out << tracking_form(listing.order)
              if listing.order.delivery_confirmation_requested_at?
                out << t('.delivery_not_confirmed_html', carrier: listing.order.shipping_carrier_name)
              end
              safe_join(out)
            end
          end
        end
      end
    end
  end
end
