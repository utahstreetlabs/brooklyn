class Admin::Users::AdminController < ApplicationController
  respond_to :json
  set_flash_scope 'admin.users.admin'
  load_resource :user, class: 'User'
  before_filter { authorize!(:grant_admin, @user) }

  def update
    @user.update_attribute(:admin, true)
    alert = view_context.admin_notice(:success, localized_flash_message(:created, name: @user.name))
    render_jsend(success: {alert: alert, userInfo: render_user_info(@user)})
  end

  def destroy
    @user.update_attribute(:admin, false)
    alert = view_context.admin_notice(:success, localized_flash_message(:deleted, name: @user.name))
    render_jsend(success: {alert: alert, userInfo: render_user_info(@user)})
  end

  protected
    def render_user_info(user)
      render_to_string(partial: '/admin/users/user_info', locals: {user: user})
    end
end
