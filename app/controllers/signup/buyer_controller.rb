module Signup
  class BuyerController < ApplicationController
    layout 'signup/buyer'

    def complete
      current_user.complete_onboarding!
      redirect_to session.delete(:signup_flow_destination) || root_path
    end
  end
end
