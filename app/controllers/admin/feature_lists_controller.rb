class Admin::FeatureListsController < AdminController
  include Controllers::AdminScoped
  include Controllers::FeatureListScoped

  set_flash_scope 'admin.feature_lists'
  load_and_authorize_resource only: :show, find_by: :slug

  def index
    @feature_lists = FeatureList.datagrid(params)
  end

  def show
    @features = @feature_list.features_with_listings
  end
end
