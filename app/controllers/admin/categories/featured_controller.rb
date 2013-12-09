class Admin::Categories::FeaturedController < AdminController
  include Controllers::AdminScoped
  include Controllers::CategoryScoped
  include Controllers::Jsendable

  set_flash_scope 'admin.categories.featured'

  set_category
  before_filter :set_feature

  def reorder
    @feature.insert_at(params[:position].to_i)
    respond_to do |format|
      format.json { render_jsend featured_listings(@category) }
    end
  end

  def destroy
    @category.delete_feature(@feature)
    set_flash_message(:notice, :removed, listing: @feature.listing.title, category: @category.name)
    redirect_to(admin_category_path(@category))
  end

protected
  def set_feature
    @feature = @category.find_feature(params[:id])
  end

  def featured_listings(category)
    result = render_to_string(partial: '/admin/categories/featured_listings.html',
      locals: {category: category, features: category.features_with_listings})
    {success: {result: result}}
  end
end
