module Listings
  module Orders
    module Buyer
      class ConfirmedExhibit < Listings::Orders::BuyerExhibit
        include Exhibitionist::RenderedWithCustom

        custom_render do |listing|
          out = []
          out << content_tag(:h2, t(".header_html"))
          out << content_tag(:p) do
            out2 = []
            out2 << t(".instructions_html", reference_number: listing.order.reference_number)
            out2 << ' '
            out2 << bootstrap_button(t(".button.check_status"), bought_dashboard_path)
            safe_join(out2)
          end
          safe_join(out)
        end
      end
    end
  end
end
