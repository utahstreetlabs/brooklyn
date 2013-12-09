module Listings
  class FeatureModalExhibit < Exhibitionist::Exhibit
    include Exhibitionist::RenderedWithHelper
    set_helper :feature_listing_modal_contents
    set_virtual_path 'listings/feature_modal_contents'

    def initialize(listing, viewer, context)
      super(listing, viewer, context)
    end

    def args
      [self]
    end
  end
end
