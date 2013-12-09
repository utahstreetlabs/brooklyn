class Settings::FeatureController < ApplicationController
  include Controllers::Jsendable

  respond_to :json, only: :update_prefs

  def update_prefs
    on_error_proc = lambda do
      render_jsend(:error => {message: "Saving your preferences failed.  Please try again."})
    end
    self.class.with_error_handling("Update preferences after handling feature", user_id: current_user.id, feature: params[:user][:feature_prefs], additionally: on_error_proc) do
      current_user.save_features_disabled_prefs(params[:user][:feature_prefs])
      render_jsend(:success => {message: I18n.t('controllers.settings.feature.updated_prefs')})
    end
  end
end
