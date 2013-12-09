class Api::CategoriesController < ApiController
  respond_to :xml

  def index
    @categories = Category.all
    render
  end
end
