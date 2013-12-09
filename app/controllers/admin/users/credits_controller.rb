class Admin::Users::CreditsController < ApplicationController
  respond_to :json
  set_flash_scope 'admin.users.credits'
  load_resource :user, class: 'User'
  before_filter { authorize!(:grant, Credit) }

  def create
    @credit = Credit.new(amount: params[:credit][:amount].to_d, expires_at: Time.zone.now + Credit.default_duration)
    @credit.user = @user
    if @credit.save
      msg = localized_flash_message(:created, amount: view_context.number_to_currency(@credit.amount))
      data = {
        alert: view_context.admin_notice(:success, msg),
        refresh: render_to_string(partial: 'admin/users/user_info', locals: {user: @user})
      }
      render_jsend(success: data)
    else
      render_jsend(fail: {modal: render_to_string(partial: 'new_modal', locals: {user: @user, credit: @credit})})
    end
  end
end
