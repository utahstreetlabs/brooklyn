module Notifications
  module Seller
    # Base class for notifications about a seller payment.
    class BaseExhibit < Notifications::BaseExhibit
      def i18n_params
        super.merge(listing_link: context.link_to_listing(listing),
          amount: context.number_to_currency(listing.proceeds))
      end

      def i18n_scope
        "exhibits.notifications.seller.payment"
      end
    end
  end
end
