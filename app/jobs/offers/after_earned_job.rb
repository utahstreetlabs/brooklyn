require 'grant_inviter_credits'

module Offers
  class AfterEarnedJob < Ladon::Job
    include Brooklyn::Sprayer
    include Brooklyn::Urls
    @queue = :users

    def self.work(offer_id, user_id)
      with_error_handling("After completion of offer #{offer_id} by #{user_id}") do
        offer = Offer.find(offer_id)
        user = User.find(user_id)
        track_offer_earned(offer)
        post_to_feed(user, offer)
      end
    end

    def self.track_offer_earned(offer)
      track_usage(Events::OfferEarn.new(offer))
    end

    def self.post_to_feed(user, offer)
      facebook_profile = user.person.for_network(:facebook)
      if facebook_profile && facebook_profile.connected? && user.allow_autoshare?(:offer_earned, :facebook)
        facebook_profile.post_to_feed(name: offer.fb_story_name, caption: offer.fb_story_caption,
                                      description: offer.fb_story_description,
                                      link: url_helpers.offer_url(offer),
                                      picture: absolute_url(offer.fb_story_image.url))
      end
    end
  end
end
