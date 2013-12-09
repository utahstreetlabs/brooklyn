class Admin::Onboarding::InterestsController < ApplicationController
  layout 'admin'
  set_flash_scope 'admin.onboarding.interests'
  load_and_authorize_resource :interest, class: 'Interest', only: [:reorder, :destroy]

  # As of 11/27/2012 this link is commented out of the admin sidebar. We are experimenting with ordering onboarding
  # interests in more complex ways, so we're disabling the reordering interface until we decide to move back to
  # ordering interests by position.

  def index
    authorize!(:manage, Interest)
    @interests = Interest.onboarding_list_by_position
  end

  def destroy
    @interest.remove_from_onboarding_list!
    set_flash_message(:notice, :destroyed, interest: @interest.name)
    redirect_to(admin_onboarding_interests_path)
  end

  def reorder
    @interest.move_within_onboarding_list!(params[:position])
    render_jsend(:success)
  end
end
