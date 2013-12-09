class Settings::ProfileController < ApplicationController
  include Controllers::Jsendable

  layout 'settings'

  def show
  end

  def update
    if current_user.update_attributes(profile_params)
      set_flash_message(:notice, :updated, scope: i18n_scope)
      redirect_to(settings_profile_path)
    else
      render :show
    end
  end

protected

  def profile_params
    keys = [:bio, :location]
    keys << :web_site if current_user.web_site_enabled?
    params[:user].slice(*keys)
  end

private
  def i18n_scope
    'settings.profile'.freeze
  end
end
