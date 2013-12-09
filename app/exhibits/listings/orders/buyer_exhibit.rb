module Listings
  module Orders
    class BuyerExhibit < Listings::OrderExhibit
      def self.factory(listing, viewer, context, options = {})
        klass = if listing.order.confirmed?
          Listings::Orders::Buyer::ConfirmedExhibit
        elsif listing.order.shipped?
          Listings::Orders::Buyer::ShippedExhibit
        elsif listing.order.delivered?
          Listings::Orders::Buyer::DeliveredExhibit
        elsif listing.order.complete?
          Listings::Orders::Buyer::CompleteExhibit
        elsif listing.order.settled?
          Listings::Orders::Buyer::SettledExhibit
        end
        klass.new(listing, viewer, context, options) if klass
      end
    end
  end
end
