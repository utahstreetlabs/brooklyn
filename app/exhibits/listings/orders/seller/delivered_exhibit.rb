module Listings
  module Orders
    module Seller
      class DeliveredExhibit < Listings::Orders::SellerExhibit
        include Exhibitionist::RenderedWithCustom

        custom_render do |listing, viewer|
          out = []
          out << content_tag(:h2, t('.header_html'))
          out << tag(:br)
          out << t('.instructions_html', review_period: tx_review_period_in_words(listing.order))
          out << content_tag(:h2, t('.review_period_ends_html', ends_at: datetime(listing.order.review_period_ends_at)))
          safe_join(out)
        end
      end
    end
  end
end
