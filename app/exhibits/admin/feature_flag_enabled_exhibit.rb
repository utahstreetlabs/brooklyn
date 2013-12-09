module Admin
  class FeatureFlagEnabledExhibit < Exhibitionist::Exhibit
    include Exhibitionist::RenderedWithHelper
    set_helper :feature_flag_enabled_button
    set_virtual_path 'admin.feature_flags.index'

    def args
      [self]
    end
  end
end
