require 'ladon'

class Autoshare::ListingLiked < Ladon::Job
  acts_as_unique_job

  @queue = :sharing

  def self.work(listing_id, listing_url, liker_id, options={})
    with_error_handling("autoshare listing liked", listing_id: listing_id, liker_id: liker_id) do
      listing = Listing.find(listing_id)
      liker = User.find(liker_id)
      liker.autoshare(:listing_liked, listing, listing_url, options.inject({}){|m,(k,v)| m[k.to_sym] = v; m})
    end
  end
end
