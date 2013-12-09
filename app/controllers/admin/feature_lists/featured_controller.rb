class Admin::FeatureLists::FeaturedController < AdminController
  include Controllers::AdminScoped
  include Controllers::FeatureListScoped
  include Controllers::Jsendable

  set_flash_scope 'admin.feature_lists.featured'

  load_and_authorize_resource :feature_list, find_by: :slug, class: 'FeatureList'
  before_filter :set_feature
  respond_to :json

  def reorder
    @feature.insert_at(params[:position].to_i)
    render_jsend(success: {
      result: feature_lists_featured_listings_exhibit(@feature_list, @feature_list.features_with_listings),
      alert: view_context.admin_notice(:success, localized_flash_message(:reordered))
    })
  end

  def destroy
    @feature_list.delete_feature(@feature)
    render_jsend(success: {
      refresh: feature_lists_featured_listings_exhibit(@feature_list, @feature_list.features_with_listings),
      alert: view_context.admin_notice(:success, localized_flash_message(:removed, feature_list: @feature_list.name))
    })
  end

protected
  def set_feature
    @feature = @feature_list.find_feature(params[:id])
  end

  def feature_lists_featured_listings_exhibit(feature_list, features)
    Admin::FeatureLists::FeaturedListingsExhibit.new(feature_list, features, current_user, view_context).render
  end
end
