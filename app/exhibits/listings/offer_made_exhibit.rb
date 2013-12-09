module Listings
  class OfferMadeExhibit < Exhibitionist::Exhibit
    include Exhibitionist::RenderedWithHelper
    set_helper :listing_make_an_offer_success_modal
    set_virtual_path 'listings/show'
    attr_reader :offer

    def initialize(listing, offer, viewer, context)
      super(listing, viewer, context)
      @offer = offer
    end

    def args
      [self, offer, viewer]
    end
  end
end
