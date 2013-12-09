class Admin::CategoriesController < AdminController
  include Controllers::AdminScoped
  include Controllers::CategoryScoped

  set_flash_scope 'admin.categories'
  set_category only: :show

  def index
    @categories = Category.datagrid(params)
  end

  def show
    @dimensions = @category.dimensions_with_values
    @features = @category.features_with_listings
  end
end
