class Admin::FeatureFlagsController < AdminController
  layout 'admin'
  set_flash_scope 'admin.feature_flags'
  load_resource

  def index
    @flags = FeatureFlag.datagrid(params)
  end
end
