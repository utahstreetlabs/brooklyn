module Listings
  class FeatureButtonExhibit < Exhibitionist::Exhibit
    include Exhibitionist::RenderedWithHelper
    set_helper :feature_listing_button
    set_virtual_path 'listings/show'
    attr_reader :featured

    def initialize(listing, viewer, context)
      super(listing, viewer, context)
      @featured = listing.features.any?
    end

    def args
      [self, featured]
    end
  end
end
