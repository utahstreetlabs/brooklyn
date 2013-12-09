module Listings
  module Orders
    module Buyer
      class DeliveredExhibit < Listings::Orders::BuyerExhibit
        include Exhibitionist::RenderedWithCustom

        custom_render do |listing|
          out = []
          out << content_tag(:h2, t(".header_html"))
          out << content_tag(:p) do
            t(".instructions_html", review_period_ends_at: datetime(listing.order.review_period_ends_at),
              help_link: mail_to(Brooklyn::Application.config.email.to.help))
          end
          out << content_tag(:h4, t(".subheader.complete"), class: "inline pull-left")
          out << ' '
          out << bootstrap_button(t(".button.complete"), finalize_listing_path(listing),
                 method: :post, disable_with: t(".disable.complete_html"))
          safe_join(out)
        end
      end
    end
  end
end
