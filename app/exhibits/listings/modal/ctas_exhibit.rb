module Listings
  module Modal
    class CtasExhibit < Exhibitionist::Exhibit
      include Exhibitionist::RenderedWithHelper
      set_helper :listing_modal_ctas
      set_virtual_path 'listings/modal'

      def args
        [ListingModal.new(self, viewer)]
      end
    end
  end
end
