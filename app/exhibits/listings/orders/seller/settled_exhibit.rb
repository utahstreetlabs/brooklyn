module Listings
  module Orders
    module Seller
      class SettledExhibit < Listings::Orders::SellerExhibit
        include Exhibitionist::RenderedWithCustom

        custom_render do |listing|
          content_tag(:h2, t(".header_html"))
        end
      end
    end
  end
end
