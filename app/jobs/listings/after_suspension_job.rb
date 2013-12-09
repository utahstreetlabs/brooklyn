require 'brooklyn/sprayer'
require 'likes/hide_likeable_likes_job'
require 'ladon'

module Listings
  class AfterSuspensionJob < Ladon::Job
    include Brooklyn::Sprayer

    @queue = :listings

    class << self
      def work(id)
        with_error_handling("After uncompletion of listing #{id}") do
          listing = Listing.find(id)
          hide_likes(listing)
          notify_seller_listing_suspended(listing)
        end
      end

      def hide_likes(listing)
        Likes::HideLikeableLikesJob.enqueue(:listing, listing.id)
      end

      def notify_seller_listing_suspended(listing)
        inject_notification(:ListingSuspended, listing.seller_id, listing_id: listing.id)
      end
    end
  end
end
