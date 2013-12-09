module Notifications
  module Listing
    # Base class for notifications about a listing.
    class BaseExhibit < Notifications::BaseExhibit
      def i18n_scope
        "exhibits.notifications.listing"
      end

      def locals
        {listing: listing, seller: seller, commenter: commenter, replier: replier, liker: liker, saver: saver, collection: collection}
      end
    end
  end
end
