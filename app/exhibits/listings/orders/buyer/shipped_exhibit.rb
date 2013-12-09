module Listings
  module Orders
    module Buyer
      class ShippedExhibit < Listings::Orders::BuyerExhibit
        include Exhibitionist::RenderedWithCustom

        custom_render do |listing|
          content_tag(:div, class: 'top-text-section') do
            content_tag(:h2, class: 'inline') do
              out = []
              out << t(".header_html")
              out << tag(:br)
              out << t(".instructions_html", carrier: listing.order.shipping_carrier_name,
                       tracking_number: listing.order.tracking_number)
              out << tracking_form(listing.order)
              out << tag(:br)
              out << tag(:br)
              out << t(".delivery_not_confirmed_html", carrier: listing.order.shipping_carrier_name)
              out << content_tag(:div, class: 'pull-right') do
                out2 = []
                out2 << bootstrap_button(t('.button.delivered'), deliver_listing_path(listing), method: :post,
                                         data: {action: 'confirm-delivery', disable_with: t('.disable.delivered_html')},
                                                class: 'margin-right')
                out2 << bootstrap_button(t('.button.not_delivered'), not_delivered_listing_path(listing), method: :post,
                                         data: {action: 'report-non-delivery',
                                                disable_with: t('.disable.not_delivered_html')})
                safe_join(out2)
              end
              safe_join(out)
            end
          end
        end
      end
    end
  end
end
