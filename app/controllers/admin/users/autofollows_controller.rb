class Admin::Users::AutofollowsController < ApplicationController
  respond_to :json, except: :index
  layout 'admin'
  set_flash_scope 'admin.users.autofollows'
  load_resource :user, class: 'User', except: :index
  before_filter { authorize!(:manage, UserAutofollow) }

  def index
    @users = User.autofollow_list
  end

  def add
    begin
      @user.add_to_autofollow_list!
    rescue ActiveRecord::RecordNotUnique
      # already on the list, so just act like everything's okay
    end
    alert = view_context.admin_notice(:success, localized_flash_message(:added, name: @user.name))
    render_jsend(success: {alert: alert, userInfo: render_user_info(@user)})
  end

  def remove
    @user.remove_from_autofollow_list
    alert = view_context.admin_notice(:success, localized_flash_message(:removed, name: @user.name))
    render_jsend(success: {alert: alert, userInfo: render_user_info(@user)})
  end

  def reorder
    @user.autofollow.insert_at(params[:position].to_i)
    @user.autofollow.save!
    render_jsend(:success)
  end

  protected
    def render_user_info(user)
      render_to_string(partial: '/admin/users/user_info', locals: {user: user})
    end
end
