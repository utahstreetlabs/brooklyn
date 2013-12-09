require 'ladon'

class Autoshare::ListingCommented < Ladon::Job
  acts_as_unique_job

  @queue = :sharing

  class << self
    def work(listing_id, listing_url, commenter_id, comment_text)
      with_error_handling("autoshare listing commented", listing_id: listing_id, commenter_id: commenter_id) do
        listing = Listing.find(listing_id)
        commenter = User.find(commenter_id)
        commenter.autoshare(:listing_commented, listing, listing_url, comment_text)
      end
    end
  end
end
