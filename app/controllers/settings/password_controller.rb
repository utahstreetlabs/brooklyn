class Settings::PasswordController < ApplicationController
  layout 'settings'

  def show
  end

  def update
    current_user.current_password = params[:user][:current_password]
    current_user.password = params[:user][:password]
    current_user.password_confirmation = params[:user][:password_confirmation]
    current_user.validate_completely! # forces password validations
    if current_user.save
      set_flash_message(:notice, :updated, scope: i18n_scope)
      redirect_to(settings_password_path)
    else
      render :show
    end
  end

private
  def i18n_scope
    'settings.password'.freeze
  end
end
