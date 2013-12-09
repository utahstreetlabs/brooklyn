module Notifications
  module Order
    # Base class for notifications about an order.
    class BaseExhibit < Notifications::BaseExhibit
      attr_reader :role

      def initialize(*)
        super
        @role = (seller == viewer ? :seller : :buyer) if seller
      end

      def buyer?
        role == :buyer
      end

      def seller?
        role == :seller
      end

      def locals
        {listing: listing, seller: seller, buyer: buyer}
      end

      def i18n_scope
        "exhibits.notifications.order"
      end

      def i18n_params
        super.merge(listing_link: context.link_to_listing(listing))
      end
    end
  end
end
