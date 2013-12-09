module Listings
  module Orders
    module Buyer
      class SettledExhibit < Listings::Orders::BuyerExhibit
        include Exhibitionist::RenderedWithCustom

        custom_render do |listing|
          content_tag(:h2, t(".header_html"))
        end
      end
    end
  end
end
