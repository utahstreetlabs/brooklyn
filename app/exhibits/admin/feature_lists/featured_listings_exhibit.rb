module Admin
  module FeatureLists
    class FeaturedListingsExhibit < Exhibitionist::Exhibit
      include Exhibitionist::RenderedWithHelper
      set_helper :admin_feature_lists_featured_listings
      set_virtual_path 'admin.feature_lists'
      attr_reader :feature_list, :features

      def initialize(feature_list, features, viewer, context)
        super(feature_list, viewer, context)
        @feature_list = feature_list
        @features = features
      end

      def args
        [feature_list, features]
      end
    end
  end
end
