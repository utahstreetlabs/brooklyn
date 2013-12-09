require 'active_support/concern'

module Controllers
  module Admin
    module ListingScoped
      extend ActiveSupport::Concern

      module ClassMethods
        def load_listing(options = {})
          before_filter(options) { load_listing }
        end
      end

      def load_listing
        @listing = Listing.find(params[:listing_id] || params[:id])
      end
    end
  end
end
