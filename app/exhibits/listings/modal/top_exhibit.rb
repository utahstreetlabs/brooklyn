module Listings
  module Modal
    class TopExhibit < Exhibitionist::Exhibit
      include Exhibitionist::RenderedWithHelper
      set_helper :listing_modal_top
      set_virtual_path 'listings/modal'

      def args
        [ListingModal.new(self, viewer, collection: options[:collection])]
      end
    end
  end
end
