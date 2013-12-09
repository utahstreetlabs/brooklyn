class Profiles::FeedbackController < ApplicationController
  include Controllers::ProfileScoped

  before_filter { respond_not_found unless feature_enabled?(:feedback) }

  load_profile_user
  require_registered_profile_user
  customize_action_event variables: [:profile_user]
  layout 'profiles'

  def selling
    @feedback = UserFeedback.create(:seller, current_user, @profile_user, params)
  end

  def buying
    @feedback = UserFeedback.create(:buyer, current_user, @profile_user, params)
  end
end
