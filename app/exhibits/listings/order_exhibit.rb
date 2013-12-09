module Listings
  class OrderExhibit < Exhibitionist::Exhibit
    def self.factory(listing, viewer, context, options = {})
      if listing.sold_by?(viewer)
        Listings::Orders::SellerExhibit.factory(listing, viewer, context, options)
      elsif listing.order.bought_by?(viewer)
        Listings::Orders::BuyerExhibit.factory(listing, viewer, context, options)
      end
    end
  end
end
