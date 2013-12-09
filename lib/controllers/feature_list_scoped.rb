module Controllers
  module FeatureListScoped
    extend ActiveSupport::Concern

    module ClassMethods
      def set_feature_list(options = {})
        before_filter(options) do
          @feature_list = FeatureList.find_by_slug!(params[:feature_list_id] || params[:id])
        end
      end
    end
  end
end
