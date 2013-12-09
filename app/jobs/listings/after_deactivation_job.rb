require 'brooklyn/sprayer'
require 'likes/hide_likeable_likes_job'
require 'ladon'

module Listings
  class AfterDeactivationJob < Ladon::Job
    @queue = :listings

    class << self
      def work(id)
        with_error_handling("After deactivation of listing #{id}") do
          listing = Listing.find(id)
          hide_likes(listing)
        end
      end

      def hide_likes(listing)
        Likes::HideLikeableLikesJob.enqueue(:listing, listing.id)
      end
    end
  end
end
