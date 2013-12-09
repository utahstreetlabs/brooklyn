module Listings
  module Orders
    class SellerExhibit < Listings::OrderExhibit
      def self.factory(listing, viewer, context, options = {})
        klass = if listing.order.confirmed?
          Listings::Orders::Seller::ConfirmedExhibit
        elsif listing.order.shipped?
          Listings::Orders::Seller::ShippedExhibit
        elsif listing.order.delivered?
          Listings::Orders::Seller::DeliveredExhibit
        elsif listing.order.complete?
          Listings::Orders::Seller::CompleteExhibit
        elsif listing.order.settled?
          Listings::Orders::Seller::SettledExhibit
        end
        klass.new(listing, viewer, context, options) if klass
      end
    end
  end
end
