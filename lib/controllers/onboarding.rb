require 'active_support/concern'

module Controllers
  # Helpers for the onboarding flow
  module Onboarding
    extend ActiveSupport::Concern

    def redirect_after_interests
      if !feature_enabled?('onboarding.follow_friends_modal') && current_user.connected_to?(:facebook)
        redirect_to(signup_buyer_friends_path)
      else
        current_user.complete_onboarding!
        redirect_to session.delete(:signup_flow_destination) || root_path
      end
    end
  end
end
