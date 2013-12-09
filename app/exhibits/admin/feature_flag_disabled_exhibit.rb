module Admin
  class FeatureFlagDisabledExhibit < Exhibitionist::Exhibit
    include Exhibitionist::RenderedWithHelper
    set_helper :feature_flag_disabled_button
    set_virtual_path 'admin.feature_flags.index'

    def args
      [self]
    end
  end
end
