module Admin
  module FeatureFlags
    class UserDisabledExhibit < Exhibitionist::Exhibit
      include Exhibitionist::RenderedWithHelper
      set_helper :feature_flag_user_disabled_button
      set_virtual_path 'admin.feature_flags.index'

      def args
        [self]
      end
    end
  end
end
