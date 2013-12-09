module Collections
  module Create
    class ListingsExhibit < Exhibitionist::Exhibit
      include Exhibitionist::RenderedWithHelper

      set_helper :create_collection_listings_modal
      attr_reader :suggested_listings

      def initialize(collection, viewer, context)
        super
        @suggested_listings = collection.
          find_suggested_listings(count: Collection.config.create.listings_modal.listing_count, includes: :photos)
      end

      def args
        [self, suggested_listings]
      end
    end
  end
end
