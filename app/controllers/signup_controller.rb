class SignupController < ApplicationController
  # generic endpoint for sending the user to the next stage in the onboarding flow
  # XXX: part of the legacy signup flow
  def onboard
    redirect_after_register
  end
end
