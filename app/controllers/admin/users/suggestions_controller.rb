class Admin::Users::SuggestionsController < ApplicationController
  respond_to :json
  set_flash_scope 'admin.users.suggestions'
  load_and_authorize_resource :user, class: 'User'

  def set
    authorize!(:manage, UserSuggestion)
    params[:user] ||= HashWithIndifferentAccess.new
    @user.suggest_for_interests!(params[:user][:suggested_interest_ids])
    alert = view_context.admin_notice(:success, localized_flash_message(:set, user: @user.name))
    render_jsend(success: {alert: alert, refresh: render_user_info(@user)})
  end

  protected
    def render_user_info(user)
      render_to_string(partial: '/admin/users/user_info.html', locals: {user: user})
    end
end
