require 'ladon'

class Autoshare::ListingActivated < Ladon::Job
  acts_as_unique_job

  @queue = :sharing

  def self.work(listing_id, listing_url)
    with_error_handling("autoshare listing activated", listing_id: listing_id) do
      listing = Listing.find(listing_id)
      listing.seller.autoshare(:listing_activated, listing, listing_url)
    end
  end
end
