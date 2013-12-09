class Settings::EmailController < ApplicationController
  layout 'settings'

  def show
  end

  def update
    current_user.email = params[:user][:email]
    current_user.email_confirmation = params[:user][:email_confirmation]
    if current_user.save
      set_flash_message(:notice, :updated, scope: i18n_scope)
      redirect_to(settings_email_path)
    else
      render :show
    end
  end

  def update_prefs
    current_user.save_email_prefs(params[:user][:email_prefs])
    set_flash_message(:notice, :updated_prefs, scope: i18n_scope)
    redirect_to(settings_email_path)
  end

private
  def i18n_scope
    'settings.email'.freeze
  end
end
