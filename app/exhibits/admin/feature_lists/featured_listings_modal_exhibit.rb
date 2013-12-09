module Admin
  module FeatureLists
    class FeaturedListingsModalExhibit < Exhibitionist::Exhibit
      include Exhibitionist::RenderedWithHelper
      set_helper :admin_feature_lists_modal_content
      set_virtual_path 'admin/feature_lists'
      attr_reader :feature_lists

      def initialize(listing, feature_lists, viewer, context)
        super(listing, viewer, context)
        @feature_lists = feature_lists
      end

      def args
        [self, feature_lists]
      end
    end
  end
end
