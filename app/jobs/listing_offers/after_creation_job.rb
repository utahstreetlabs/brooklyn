require 'brooklyn/sprayer'
require 'ladon'

module ListingOffers
  class AfterCreationJob < Ladon::Job
    include Brooklyn::Sprayer

    @queue = :listings

    def self.work(id)
      with_error_handling("After creation of listing offer #{id}") do
        offer = ListingOffer.find(id)
        send_email_to_admin(offer)
        update_mixpanel(offer)
      end
    end

    def self.send_email_to_admin(offer)
      send_email(:created_for_admin, offer)
    end

    def self.update_mixpanel(offer)
      track_usage(Events::ListingOfferCreate.new(offer))
    end
  end
end
