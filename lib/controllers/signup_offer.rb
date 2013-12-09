require 'active_support/concern'

module Controllers
  # Support for signup offers
  #
  # We support offering different credits to different users based on
  # Vanity A/B experimental groups. These utilities make it easier to work
  # with these "signup offers" in controllers.
  module SignupOffer
    extend ActiveSupport::Concern
    include Brooklyn::ABTesting

    included do
      set_signup_offer
      helper_method :signup_offer
    end

    def signup_offer
      if Offer.respond_to?(:find_by_ab_tag)
        @signup_offer ||= Offer.find_by_ab_tag(ab_test(latest_active_experiment(:signup_credit)))
      end
    end

    def set_signup_offer?
      (not session[:offer_id]) and anonymous_user? and experiment_active?(:signup_credit) and signup_offer
    end

    module ClassMethods
      def set_signup_offer
        before_filter do
          session[:offer_id] = signup_offer.uuid if set_signup_offer?
        end
      end
    end
  end
end
