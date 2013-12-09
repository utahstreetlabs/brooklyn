class CategoriesController < ApplicationController
  skip_before_filter :require_login_only
  respond_to :json, :only => :autocomplete

  def autocomplete
    scope = Category.scoped
    scope = scope.where('name like ?', "%#{params[:term]}%") if params[:term].present?
    categories = scope.order(:name).limit(params[:limit] || 10).all
    respond_with(categories.map { |cat| {
      :name => cat.name,
      :slug => cat.slug
      }
    })
  end
end
