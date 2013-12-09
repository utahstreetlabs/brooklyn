module Collections
  module Create
    class SuccessExhibit < Exhibitionist::Exhibit
      include Exhibitionist::RenderedWithHelper

      set_helper :create_collection_success_modal
      attr_reader :interesting_listings

      def initialize(collection, viewer, context)
        super
        @interesting_listings = viewer.
          recently_created_interesting_listings(count: Collection.config.create.success_modal.listing_count,
                                                includes: :photos)
      end

      def args
        [self, interesting_listings]
      end
    end
  end
end
