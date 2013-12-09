module Listings
  class MakeAnOfferExhibit < Exhibitionist::Exhibit
    include Exhibitionist::RenderedWithHelper
    set_helper :listing_price_box_make_an_offer
    set_virtual_path 'listings/show'
    attr_reader :offer

    def initialize(listing, offer, viewer, context)
      super(listing, viewer, context)
      @offer = offer
    end

    def args
      [self, viewer, offer: offer]
    end
  end
end
