require 'ladon'

class EmailListingActivated < Ladon::Job
  include Brooklyn::Sprayer
  @queue = :email

  def self.work(listing_id)
    listing = Listing.find(listing_id)
    unless blacklisted_activators.include?(listing.seller_id)
      listing.seller.each_interested_user(with_prefs: true) do |follower, prefs|
        context = "emailing user #{follower.id} about activation of listing #{listing_id}"
        with_error_handling(context, listing_id: listing_id) do
          if follower.allow_email?(:follower_list, preferences: prefs)
            send_email(:activated, listing, follower.to_job_hash)
          end
        end
      end
    end
  end

  def self.blacklisted_activators
    Brooklyn::Application.config.jobs.email_listing_activated_blacklist
  end
end
