require 'brooklyn/sprayer'
require 'ladon'

module Listings
  class AfterApprovalJob < Ladon::Job
    include Brooklyn::Sprayer

    @queue = :listings

    class << self
      def work(id)
        with_error_handling("After approval of listing #{id}") do
          listing = Listing.find(id)
          inject_activated_story(listing)
        end
      end

      def inject_activated_story(listing)
        inject_listing_story(:listing_activated, listing.seller_id, listing, {}, feed: [:ev, :ylf])
      end
    end
  end
end
