class Admin::Interests::UsersController < ApplicationController
  respond_to :json, only: :reorder
  set_flash_scope 'admin.interests.users'
  load_and_authorize_resource :interest, class: 'Interest'
  # authorizing the user resource means a regular admin cannot destroy an interest-user
  # association, which feels over-protective.  we require a superuser to destroy an
  # actual user.
  load_resource :user, class: 'User'

  def destroy
    @interest.remove_from_suggested_user_list(@user)
    set_flash_message(:notice, :destroyed, user: @user.name)
    redirect_to(admin_interest_path(@interest))
  end

  def reorder
    @interest.move_within_suggested_user_list!(@user, params[:position])
    render_jsend(:success)
  end
end
