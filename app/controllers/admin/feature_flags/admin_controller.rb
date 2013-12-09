module Admin::FeatureFlags
  class AdminController < AdminController
    load_resource :feature_flag, class: 'FeatureFlag'
    respond_to :json

    def create
      @feature_flag.update_attributes!(admin_enabled: true)
      render_jsend(success: {
        refresh: Admin::FeatureFlags::AdminEnabledExhibit.new(@feature_flag, current_user, view_context).render
      })
    end

    def destroy
      @feature_flag.update_attributes!(admin_enabled: false)
      render_jsend(success: {
        refresh: Admin::FeatureFlags::AdminDisabledExhibit.new(@feature_flag, current_user, view_context).render
      })
    end
  end
end
