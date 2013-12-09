module Events::OfferProperties
  extend ActiveSupport::Concern

  module ClassMethods
    def offer_eligible_users(offer)
      if offer.new_users? && offer.existing_users?
        :all
      elsif offer.new_users?
        :new
      elsif offer.existing_users?
        :existing
      else
        :none
      end
    end

    def offer_properties(offer_id)
      offer = Offer.find(offer_id)
      {
        offer_name: offer.name, ab_test_id: offer.ab_tag, offer_amount: offer.amount,
        minimum_purchase: offer.minimum_purchase, credit_duration: offer.duration,
        offer_expires_at: offer.expires_at, eligible_users: offer_eligible_users(offer)
      }
    end
  end
end
