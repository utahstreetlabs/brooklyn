require 'brooklyn/sprayer'
require 'ladon'
require 'likes/reveal_likeable_likes_job'

module Listings
  class AfterReactivationJob < Ladon::Job
    @queue = :listings

    class << self
      def work(id)
        with_error_handling("After reactivation of listing #{id}") do
          listing = Listing.find(id)
          reveal_likes(listing)
        end
      end

      def reveal_likes(listing)
        Likes::RevealLikeableLikesJob.enqueue(:listing, listing.id)
      end
    end
  end
end
