class SandboxController < ApplicationController
  #include Controllers::DashboardScoped
  #include Controllers::Sortable

  helper_method :profile_user
  before_filter :require_admin

  layout 'application'

  #load_sidebar
  #load_follow_suggestions

  def profile_user
    current_user
  end
end
