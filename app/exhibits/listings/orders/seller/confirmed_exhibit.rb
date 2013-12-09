module Listings
  module Orders
    module Seller
      class ConfirmedExhibit < Listings::Orders::SellerExhibit
        include Exhibitionist::RenderedWithCustom

        def initialize(*)
          super
          order.build_shipment unless order.shipment
        end

        custom_render do |listing, viewer|
          if listing.prepaid_shipping?
            if listing.order.expired_shipping_label?
              render('listings/seller/confirmed_prepaid_shipping_expired_label', listing: listing)
            else
              render('listings/seller/confirmed_prepaid_shipping', listing: listing,
                     ship_from: ShipFrom.create(listing, viewer.sorted_shipping_addresses.all),
                     new_address: PostalAddress.new_shipping_address)
            end
          else
            render('listings/seller/confirmed_basic_shipping', listing: listing)
          end
        end
      end
    end
  end
end
