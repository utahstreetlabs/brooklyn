module Listings
  class FeatureSuccessModalExhibit < Exhibitionist::Exhibit
    include Exhibitionist::RenderedWithHelper
    set_helper :feature_listing_success_modal
    set_virtual_path 'listings/feature_success_modal'

    def initialize(listing, viewer, context)
      super(listing, viewer, context)
    end

    def args
      [self]
    end
  end
end
