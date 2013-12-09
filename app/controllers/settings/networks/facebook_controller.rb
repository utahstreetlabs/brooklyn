class Settings::Networks::FacebookController < Settings::NetworksController
  include Controllers::Jsendable

  before_filter :load_profile, except: [:disable_timeline]
  respond_to :json, only: [:disable_timeline, :timeline_permission]

  def disable_timeline
    if (current_user.allow_feature?(:request_timeline_facebook) &&
        current_user.save_features_disabled_prefs(:request_timeline_facebook => '0'))
      return render_jsend(success: {disabled: true})
    end
    render_jsend(success: {disabled: false})
  end

  def timeline_permission
    on_error_proc = lambda do
      render_jsend(:error => {message: "Fetching preferences failed.  Please try again."})
    end
    self.class.with_error_handling("Fetch timeline permissions", user_id: current_user.id, additionally: on_error_proc) do
      missing = @profile.missing_live_permissions([:publish_actions])
      render_jsend(success: {missing: missing.any?})
    end
  end
end
