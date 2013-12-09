module Controllers
  module CategoryScoped
    extend ActiveSupport::Concern

    module ClassMethods
      def set_category(options = {})
        before_filter(options) do
          @category = Category.find_by_slug!(params[:category_id] || params[:id])
        end
      end
    end
  end
end
