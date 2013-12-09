module Layouts
  module HamburgerHelper # lulz
    def masthead_hamburger(viewer)
      content_tag(:div, id: 'hb-hamburger') do
        out = []
        out << masthead_hamburger_button(desktop: true, phone: true)
        out << masthead_hamburger_counter if viewer
        safe_join(out)
      end
    end

    # backwards-compatible with old masthead
    def masthead_hamburger_button(options = {})
      options = options.reverse_merge(data: {})
      link_classes = %w(btn btn-navbar)
      # hiding on desktop and phone are legacy features for the old masthead. can remove them if/when we get rid of it.
      link_classes << 'hidden-desktop' unless options.delete(:desktop)
      link_classes << 'hidden-phone' unless options.delete(:phone)
      options[:base_class] = class_attribute(link_classes)
      options[:data][:toggle] = 'hamburger'
      target = options.delete(:target)
      button_tag(bootstrap_html_options(options)) do
        safe_join((1..3).map { content_tag(:span, nil, class: 'icon-bar') })
      end
    end

    def masthead_hamburger_counter
      total = unviewed_notification_count
      styles = {}
      styles[:display] = 'none' unless total > 0
      content_tag(:div, id: 'hamburger-counter', style: style_attribute(styles)) do
        total = '' unless total > 0
        out = []
        out << bootstrap_badge(total, level: :important, data: {role: 'total-pill'})
        out << content_tag(:span, unviewed_notification_count, style: 'display:none',
                           data: {role: 'notification-pill', invisible: true})
        safe_join(out)
      end
    end

    def hamburger_tray(viewer)
      return if masthead_hidden?
      classes = %w(hb-tray)
      classes << 'hb-auto' if feature_enabled?('hamburger.auto')
      tray_options = {
        id: 'hb-tray',
        class: class_attribute(classes),
        stacked: true
      }

      tabs = []
      if viewer
        tabs << hamburger_profile_tab(viewer)
      end
      tabs << hamburger_home_tab
      if viewer
        tabs << hamburger_notifications_tab(viewer)
      end
      tabs << hamburger_trending_tab
      tabs << hamburger_new_arrivals_tab
      tabs << hamburger_browse_tab
      if viewer
        tabs << hamburger_account_settings_tab
        tabs << hamburger_dashboard_tab
        if admin?
          tabs << hamburger_admin_tab
        end
        tabs << hamburger_logout_tab
      end

      content_tag(:div, tray_options) do
        out = []
        out << content_tag(:div, id: 'hb-tray-contents') do
          out2 = []
          out2 << hamburger_search
          out2 << bootstrap_tabs(tabs.compact)
          # Hamburger footer requires a hidden placeholder as hack to take up space in page despite styling.
          out2 << hamburger_footer_placeholder
          safe_join(out2)
        end
        out << hamburger_footer
        safe_join(out)
      end
    end

    def hamburger_search
      content_tag(:div, id: 'search-tab') do
        form_tag(listings_path, method: :get) do
          out = []
          out << text_field_tag(:search, params[:search], placeholder: t('hamburger.search.placeholder'))
          out << dot_spinner
          safe_join(out)
        end
      end
    end

    def hamburger_footer
      content_tag(:div, id: 'hamburger-footer') do
        out = []
        out << link_to('About', 'http://corporate.copious.com/about-us', class: 'footer-links')
        out << link_to_help_center('Help')
        out << link_to_terms
        out << link_to_privacy_policy('Privacy')
        out << link_to_transaction_policy('Policy')
        out << content_tag(:div, t('hamburger.footer.company', year: Date.today.year))
        safe_join(out)
      end
    end

    def hamburger_footer_placeholder
      content_tag(:div, '', id: 'hamburger-footer-placeholder')
    end

    def hamburger_home_tab
      {text: t('hamburger.home'), href: root_path, item: {id: 'home-tab'}}
    end

    def hamburger_profile_tab(viewer)
      text = safe_join([user_avatar_xsmall_nolink(viewer), viewer.name], ' ')
      {text: text, href: public_profile_path(viewer), item: {id: 'profile-tab'}}
    end

    def hamburger_notifications_tab(viewer)
      style = 'display:none' unless unviewed_notification_count > 0
      counter = bootstrap_badge(unviewed_notification_count, level: :important, style: style, class: 'pull-right',
                                data: {role: 'notification-pill'})
      text = safe_join([t('hamburger.notifications'), counter])
      {text: text, href: notifications_path, item: {id: 'notifications-tab'}}
    end

    def hamburger_trending_tab
      {text: t('hamburger.trending'), href: trending_path, item: {id: 'trending-tab'}}
    end

    def hamburger_new_arrivals_tab
      {text: t('hamburger.new_arrivals'), href: new_arrivals_for_sale_path, item: {id: 'new-arrivals-tab'}}
    end

    def hamburger_browse_tab
      menu_items = Category.find_with_at_least_one_active_listing.map do |category|
        {text: category.name, href: browse_for_sale_path(category), link: {data: {category: category.name}}}
      end
      text = bootstrap_dropdown do
        out = []
        out << bootstrap_dropdown_toggle(t('hamburger.browse'), caret: true)
        out << bootstrap_dropdown_menu(menu_items)
        safe_join(out)
      end
      {text: text,
       item: {id: 'browse-tab', active: params[:controller] == 'search_browse' && params[:action] == 'browse'}}
    end

    def hamburger_account_settings_tab
      {text: t('hamburger.account_settings'), href: settings_profile_path, item: {id: 'settings-tab'}}
    end

    def hamburger_dashboard_tab
      {text: t('hamburger.dashboard'), href: for_sale_dashboard_path, item: {id: 'dashboard-tab'}}
    end

    def hamburger_admin_tab
      {text: t('hamburger.admin'), href: admin_dashboard_path, item: {id: 'admin-tab'}}
    end

    def hamburger_logout_tab
      {text: t('hamburger.log_out'), href: logout_path, item: {id: 'logout-tab'}}
    end
  end
end
