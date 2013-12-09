module Listings
  class SaveManagerExhibit < Exhibitionist::Exhibit
    include Exhibitionist::RenderedWithHelper
    set_helper :save_listing_to_collection_modal
    set_virtual_path 'listings/modal'

    def args
      [self, options[:collections], options]
    end
  end
end
