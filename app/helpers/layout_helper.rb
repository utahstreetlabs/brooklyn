module LayoutHelper
  # call this at the top of views that shouldn't have a footer
  def hide_footer
    @footer_hidden = true
  end

  def footer_hidden?
    !!@footer_hidden
  end

  # call this at the of views that should not have a header at all
  def hide_masthead
    @masthead_hidden = true
  end

  def masthead_hidden?
    @masthead_hidden
  end

  def masthead_active?
    !@masthead_deactivated
  end

  # call this at the of views that should not have an active header
  def deactivate_masthead
    @masthead_deactivated = true
  end

  def hamburger_active?
    !@hamburger_deactivated
  end

  def deactivate_hamburger
    @hamburger_deactivated = true
  end

  def footer_menu_active?
    !@footer_menu_deactivated
  end

  # call this at the of views that should not have an active header
  def deactivate_footer_menu
    @footer_menu_deactivated = true
  end

  def hamburger_classes(classes = [])
    classes << 'hb-neighbor' if feature_enabled?('hamburger')
    classes << 'hb-auto' if feature_enabled?('hamburger.auto')
    class_attribute(classes)
  end

  def welcome_header(header)
    case header
    when :logged_in_home
      home_user_header
    when :logged_out_home
      logged_out_header
    when :trending
      trending_header
    when :feed
      feed_header
    end
  end

  def dot_spinner
    content_tag(:div, id: 'spinner_loading', class: 'spinner', style: 'display: none;',
                data: {role: :spinner}) do
      spinner = []
      spinner << content_tag(:div, '', id: 'circleG_1', class: 'circleG')
      spinner << content_tag(:div, '', id: 'circleG_2', class: 'circleG')
      spinner << content_tag(:div, '', id: 'circleG_3', class: 'circleG')
      safe_join(spinner)
    end
  end

  def masthead_browse_menu
    menu_items = [
      ['New Arrivals', new_arrivals_for_sale_path],
      ['Trending', trending_path],
      ['Most Popular', browse_for_sale_path(sort: :popular)],
      ['All Listings', browse_for_sale_path],
      ['Categories', nil, class: 'nav-header'],
    ]
    menu_items += Category.find_with_at_least_one_active_listing.map do |c|
      [c.name, browse_for_sale_path(c, sort: params[:sort]), {:class => 'browse-menu-category'}]
    end
    bootstrap_dropdown(:class => 'header-title-explore') do
      bootstrap_dropdown_toggle('', caret: true) +
      bootstrap_dropdown_menu(menu_items)
    end
  end

  def masthead_connect_menu
    menu_items = [
      ['Who to Follow', connect_who_to_follow_index_path],
      ['Invite Friends', connect_invites_path]
    ]
    bootstrap_dropdown(:class => 'header-title-connect') do
      bootstrap_dropdown_toggle('', caret: true) +
      bootstrap_dropdown_menu(menu_items)
    end
  end

  def masthead_search_form(name)
    form_tag(listings_path, class: 'navbar-search', method: :get, id: 'search_listings') do
      content_tag(:div, id: 'search_box', class: 'pull-left') do
        content_tag(:div, nil, class: 'pull-left') do
          text_field_tag(name, params[name], placeholder: t('layout.application.search_placeholder_html')) +
          link_to('', '#', class: 'search_clear')
        end +
        content_tag(:button, t('layout.application.search'), class: 'button pull-left', type: :submit, id: 'searchButton',
          style: 'display:none') + dot_spinner
      end
    end
  end

  def masthead_brand
    container_classes = %w(header-home)
    container_classes << 'deactivate-header' unless masthead_active?
    content_tag(:div, class: class_attribute(container_classes)) do
      content_tag(:h2, class: 'brand') do
        link_to_if(masthead_active?, 'Copious', root_path, id: 'masthead-logo')
      end
    end
  end

  def masthead_account_menu(user)
    scope = 'masthead.account_menu'
    menu_items = [
      [t(:title, scope: scope), nil, class: 'nav-header'],
      [t(:profile, scope: scope), public_profile_path(user)]
    ]
    if feature_enabled?('collections.page')
      menu_items << [t(:collections, scope: scope), public_profile_collections_path(user)]
    end
    menu_items.concat([
      [t(:loves, scope: scope), liked_public_profile_path(current_user)],
      [t(:follows, scope: scope), collections_public_profile_following_path(current_user)],
      [t(:followers, scope: scope), followers_public_profile_path(current_user)],
      [t(:marketplace, scope: scope), nil, class: 'nav-header'],
      [t(:listings, scope: scope), for_sale_dashboard_path],
      [t(:orders, scope: scope), sold_dashboard_path],
      [t(:purchases, scope: scope), bought_dashboard_path]
    ])
    if feature_enabled?(:feedback)
      menu_items << [t(:feedback, scope: scope), selling_public_profile_feedback_index_path(user)]
    end
    menu_items += [
      ['', nil, class: 'nav-header faux-nav-header'],
      [t(:settings, scope: scope), settings_profile_path],
      [t(:log_out, scope: scope), logout_path],
    ]
    menu_items.unshift([t(:admin, scope: scope), admin_dashboard_path]) if user.admin?
    bootstrap_dropdown(:class => 'account-dropdown') do
      bootstrap_dropdown_toggle(caret: true) do
        user_avatar_xsmall_nolink(user) +
        content_tag(:span, '', class: 'kill-margin-left clearfix block-element' )
      end +
      bootstrap_dropdown_menu(menu_items)
    end
  end

  def masthead_notification_pill(user)
    style = unviewed_notification_count == 0 ? 'display:none' : ''
    content_tag(:span, unviewed_notification_count, class: 'notification-pill', style: style,
      data: {role: 'notification-pill', poller: poll_notifications?})
  end

  def nav_li(name, options = {}, html_options = {}, &block)
    tag_options = {}
    tag_options[:class] = 'selected' if current_page?(options)
    content_tag(:li, tag_options) do
      link_to_unless_current(name, options, html_options) + (block_given? ? capture(&block) : '')
    end
  end

  def masthead_add_button(viewer, options = {})
    html_options = options.reverse_merge(
      id: 'masthead-add-button',
      data: {role: 'add-widget', source: 'masthead-add-button'}
    )
    if viewer
      html_options[:type] = :button
      html_options[:toggle_modal] = 'add'
      html_options[:data][:user] = viewer.slug
      bootstrap_button(t('masthead.button.add'), html_options)
    else
      bootstrap_button(t('masthead.button.add'), signup_path, html_options)
    end
  end

  def notification_count_poller_meta_tag
    tag(:meta, name: 'copious:notifications:poll', content: poll_notifications?)
  end

  def story_count_poller_meta_tag
    tag(:meta, name: 'copious:stories:poll', content: poll_new_stories?)
  end

  def feature_flag_meta_tag(feature_flag, meta_name = feature_flag)
    if feature_enabled?(feature_flag)
      tag(:meta, name: "copious:ff:#{meta_name}", content: 'enabled')
    end
  end

  def history_manager_meta_tag
    feature_flag_meta_tag('history_manager')
  end

  def new_profile_modal_meta_tag
    feature_flag_meta_tag('onboarding.create_profile_modal')
  end

  def feature_flag_meta_tags
    out = []
    out << history_manager_meta_tag
    out << new_profile_modal_meta_tag
    safe_join(out)
  end

  def copious_logo_image_tag
    image_tag 'layout/Logo-50x50.png'
  end

  def copious_credit_image_tag
    image_tag 'icons/icon-credit-earned.png'
  end
end
