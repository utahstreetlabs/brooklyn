module Listings
  class ModalExhibit < Exhibitionist::Exhibit
    include Exhibitionist::RenderedWithHelper
    set_helper :listing_modal
    set_virtual_path 'listings/modal'

    def args
      [ListingModal.new(self, viewer)]
    end
  end
end
