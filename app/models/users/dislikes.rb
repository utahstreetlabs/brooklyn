require 'active_support/concern'

module Users
  module Dislikes
    extend ActiveSupport::Concern

    def dislike(listing)
      dislikes.create(listing: listing)
    end

    def dislikes?(listing)
      dislikes.where(listing_id: listing.id).exists?
    end
  end
end
