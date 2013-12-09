module Admin::FeatureFlags
  class UserController < AdminController
    load_resource :feature_flag, class: 'FeatureFlag'
    respond_to :json

    def create
      @feature_flag.update_attributes!(enabled: true)
      render_jsend(success: {
        refresh: Admin::FeatureFlags::UserEnabledExhibit.new(@feature_flag, current_user, view_context).render
      })
    end

    def destroy
      @feature_flag.update_attributes!(enabled: false)
      render_jsend(success: {
        refresh: Admin::FeatureFlags::UserDisabledExhibit.new(@feature_flag, current_user, view_context).render
      })
    end
  end
end
