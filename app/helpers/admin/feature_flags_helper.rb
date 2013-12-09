module Admin
  module FeatureFlagsHelper
    def feature_flag_user_button_target(flag)
      "flag-#{flag.id}-user-enabled"
    end

    def feature_flag_admin_button_target(flag)
      "flag-#{flag.id}-admin-enabled"
    end

    def feature_flag_user_enabled_button(flag)
      bootstrap_button(t('.button.enabled.label'), admin_feature_flag_user_path(flag), method: :delete, remote: :multi,
                       disable_with: t('.button.enabled.disabled_html'), class: 'active',
                       data: {action: 'disable', toggle: 'button', refresh: "##{feature_flag_user_button_target(flag)}"})
    end

    def feature_flag_user_disabled_button(flag)
      bootstrap_button(t('.button.disabled.label'), admin_feature_flag_user_path(flag), method: :post, remote: :multi,
                       disable_with: t('.button.disabled.disabled_html'),
                       data: {action: 'enable', toggle: 'button', refresh: "##{feature_flag_user_button_target(flag)}"})
    end

    def feature_flag_admin_enabled_button(flag)
      bootstrap_button(t('.button.enabled.label'), admin_feature_flag_admin_path(flag), method: :delete, remote: :multi,
                       disable_with: t('.button.enabled.disabled_html'), class: 'active',
                       data: {action: 'disable', toggle: 'button', refresh: "##{feature_flag_admin_button_target(flag)}"})
    end

    def feature_flag_admin_disabled_button(flag)
      bootstrap_button(t('.button.disabled.label'), admin_feature_flag_admin_path(flag), method: :post, remote: :multi,
                       disable_with: t('.button.disabled.disabled_html'),
                       data: {action: 'enable', toggle: 'button', refresh: "##{feature_flag_admin_button_target(flag)}"})
    end
  end
end
