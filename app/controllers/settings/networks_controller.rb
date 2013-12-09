class Settings::NetworksController < ApplicationController
  include Controllers::NetworkProfileScoped

  layout 'settings'
  customize_action_event only: [:destroy], params: [:id]
  before_filter :load_profile, except: [:index, :allow_autoshare, :never_autoshare]
  respond_to :json, only: [:allow_autoshare, :never_autoshare]

  def index
  end

  def update
    current_user.save_autoshare_prefs(@profile.network, params[:user][:autoshare_prefs])
    current_user.preferences.save_never_autoshare(params[:never_autoshare] == '1')
    set_flash_message(:notice, :updated_prefs, scope: i18n_scope)
    redirect_to(settings_networks_path)
  end

  def destroy
    @profile.disconnect!
    track_usage(:disconnect_network, network: params[:network])
    set_flash_message(:notice, :disconnected, network: view_context.profile_name(@profile), scope: i18n_scope)
    redirect_to settings_networks_path
  end

  def allow_autoshare
    current_user.preferences.allow_autoshare!(params[:network].to_sym, params[:event].to_sym)
    render_jsend(:success)
  end

  def never_autoshare
    if current_user.preferences.save_never_autoshare(true)
      render_jsend(success: {confirm: "OK"}) # XXX: confirmation message
    else
      render_jsend(error: "could not save autoshare preference")
    end
  end

private
  # Return true if this request is enabling any autoshare preferences.
  def enabling_autoshare?
    params[:user][:autoshare_prefs].any? do |p|
      params[:user][:autoshare_prefs][p] == "1"
    end
  end

  def i18n_scope
    'settings.networks'.freeze
  end
end
