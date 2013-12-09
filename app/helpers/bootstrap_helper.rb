# coding: utf-8
module BootstrapHelper
  def bootstrap_navbar(options = {}, &block)
    navbar_base_class = ['navbar']
    navbar_base_class << 'navbar-fixed-top' if options.delete(:fixed_top)
    navbar_options = bootstrap_html_options(options.fetch(:navbar, {}).merge(base_class: navbar_base_class.join(' ')))
    inner_options = bootstrap_html_options(options.fetch(:inner, {}).merge(base_class: 'navbar-inner'))
    container_options = bootstrap_html_options(options.fetch(:container, {}).merge(base_class: 'container'))
    content_tag(:div, navbar_options) do
      content_tag(:div, inner_options) do
        content_tag(:div, container_options) do
          yield
        end
      end
    end
  end

  def bootstrap_nav_links(options = {}, &block)
    html_options = bootstrap_html_options(options.merge(base_class: :nav))
    content_tag(:ul, html_options) do
      yield
    end
  end

  def bootstrap_nav_link(*args, &block)
    options = args.extract_options!
    base_class = Set.new
    content = if block_given?
      capture { yield }
    elsif args.size == 1
      args.first
    else
      text = args.first
      url = args.second
      # XXX: puts an obnoxious effect on top nav bar links. that effect needs to be removed.
      # base_class << 'active' if current_page?(url)
      link_to(text, url, options.delete(:link))
    end
    base_class << 'active' if options.delete(:active)
    options[:base_class] = base_class.to_a.join(' ') if base_class.any?
    html_options = bootstrap_html_options(options)
    content_tag(:li, content, html_options)
  end

  def bootstrap_nav_section(options = {}, &block)
    html_options = bootstrap_html_options(options.merge(base_class: :nav))
    content_tag(:div, html_options) do
      yield
    end
  end

  def bootstrap_nav_list(options = {}, &block)
    ul_options = bootstrap_html_options(options.merge(base_class: 'nav nav-list'))
    content_tag(:ul, ul_options) do
      yield
    end
  end

  def bootstrap_nav_list_section(header, items, options = {})
    out = ''.html_safe
    if header
      header_options = bootstrap_html_options(options.fetch(:header, {}).merge(base_class: 'nav-header'))
      out << content_tag(:li, header, header_options)
    end
    out << bootstrap_list_items(items, options)
    out
  end

  def bootstrap_dropdown(options = {}, &block)
    html_options = bootstrap_html_options(options.merge(base_class: :dropdown))
    content_tag(:div, html_options) do
      yield
    end
  end

  def bootstrap_dropdown_toggle(*args, &block)
    options = args.extract_options!
    caret = options.delete(:caret)
    html_options = bootstrap_html_options(options.merge(base_class: :'dropdown-toggle', data: {toggle: :dropdown}))
    text = content_tag(:div, data: {role: 'dropdown-title'}) do
      out = []
      out << (block_given?? capture { yield } : args.first.html_safe)
      out << content_tag(:b, nil, :class => 'caret') if caret
      safe_join(out)
    end
    bootstrap_button(text, html_options.merge(type: :button))
  end

  def bootstrap_dropdown_menu(items, options = {})
    options = options.dup
    item_options = options.delete(:item) || {}
    html_options = bootstrap_html_options(options.merge(base_class: :'dropdown-menu', data: {role: :'dropdown-menu'}))
    content_tag(:ul, html_options) do
      bootstrap_list_items(items, item_options)
    end
  end

  def bootstrap_html_options(options = {})
    css_class = []
    pull = options.delete(:pull)
    css_class << "pull-#{pull}" if pull
    base_class = options.delete(:base_class)
    css_class << base_class.to_s if base_class
    html_options_with_base_class(css_class.join(' '), options)
  end

  def dropdown_search_form(*args, &block)
    options = args.extract_options!
    html_options = bootstrap_html_options(options.merge(base_class: :'navbar-search'))
    content_tag(:form, *args, options, &block)
  end

  def bootstrap_tabs(items, options = {})
    base_class = ['nav nav-tabs copious-tabs']
    base_class << 'nav-stacked' if options.delete(:stacked)
    html_options = bootstrap_html_options(options.merge(base_class: base_class.join(' ')))
    content_tag(:ul, html_options) do
      bootstrap_list_items(items, options)
    end
  end

  def bootstrap_dropdown_list_item(text, menu_items, options = {}, &block)
    base_classes = %w(dropdown)
    base_classes << 'active' if options[:active]
    container_options =
      bootstrap_html_options(options.fetch(:container, {}).merge(base_class: class_attribute(base_classes)))
    content_tag(:li, container_options) do
      out = []
      toggle_options = bootstrap_html_options(options.fetch(:toggle, {}))
      out << bootstrap_dropdown_toggle(text, toggle_options)
      menu_options = bootstrap_html_options(options.fetch(:menu, {}))
      out << bootstrap_dropdown_menu(menu_items, menu_options)
      safe_join(out)
    end
  end

  def bootstrap_list_items(items, options = {})
    formatted = options.delete(:formatted)
    divider = options.delete(:divider)
    divider = divider ? content_tag(:span, '/', :class => 'divider') : ''
    unless_current = options.delete(:unless_current)
    with_active = options.delete(:with_active)
    with_active = true if with_active.nil?
    out = items.inject([]) do |m, i|
      if i.is_a?(Proc)
        text = capture { i.call }
      elsif i.is_a?(Array)
        text = i[0]
        href = i[1]
        item_options = i[2] if i.size > 2
        link_options = i[3] if i.size > 3
      elsif i.is_a?(Hash)
        text = i[:text]
        href = i[:href]
        item_options = i.fetch(:item, {})
        link_options = i.fetch(:link, {})
      else
        text = i
      end
      item_options ||= {}
      item_base_class = []
      item_base_class << 'active' if with_active && ((href && current_page?(href)) || item_options.delete(:active))
      item_options = bootstrap_html_options(item_options.merge(base_class: item_base_class.join(' ')))
      link_options ||= {}
      unless_current = link_options.delete(:unless_current) if unless_current.nil?
      if formatted
        m << text
      else
        m << content_tag(:li, item_options) do
          if href.present?
            if unless_current
              link_to_unless_current(text, href, link_options)
            else
              link_to(text, href, link_options)
            end
          else
            text
          end
        end
      end
    end
    safe_join(out, divider)
  end

  def bootstrap_icon(name, text = nil, options = {})
    out = []
    classes = ["icon-#{name}"]
    classes << 'icon-white' if options.delete(:inverted_icon)
    out << content_tag(:i, nil, class: classes.join(' '))
    out << text if text
    out.join(' ').html_safe
  end

  def bootstrap_tabbable_nav(tab_items, tab_panes, options = {})
    tab_items = tab_items.map.with_index do |item, i|
      item_options = item[2] if item.size > 2
      item_options ||= {}
      item_options = html_options_with_base_class :active, item_options if options[:active] == i
      link_options = item[3] if item.size > 3
      link_options ||= {}
      link_options[:data] = link_options.fetch(:data, {}).update(toggle: 'tab')
      item += [item_options, link_options]
    end
    content_tag :div, class: 'tabbable' do
      bootstrap_tabs(tab_items, class: 'nav') +
      content_tag(:div, class: 'tab-content') do
        tab_panes.each.with_index.inject(''.html_safe) do |m, ((id, content), i)|
          css_class = ['tab-pane']
          css_class << 'active' if options[:active] == i
          m << content_tag(:div, content, id: id, class: css_class.join(' '))
        end
      end
    end
  end

  def bootstrap_toolbar(options = {}, &block)
    html_options = bootstrap_html_options(options.merge(base_class: 'btn-toolbar'))
    content_tag :div, html_options, &block
  end

  def bootstrap_button_group(options = {}, &block)
    options[:data] ||= {}
    toggle = options.delete(:toggle)
    options[:data][:toggle] = "buttons-#{toggle}" if toggle
    options[:base_class] = :'btn-group'
    html_options = bootstrap_html_options(options)
    content_tag :div, html_options, &block
  end

  BOOTSTRAP_BUTTON_CONDITIONS = {primary: :primary, info: :info, success: :success, warning: :warning, danger: :danger, inverse: :inverse, green_light: :green_light, yellow_light: :yellow_light, link: :link}

  def bootstrap_button_condition(condition)
    return nil if condition.blank?
    return BOOTSTRAP_BUTTON_CONDITIONS[condition] if BOOTSTRAP_BUTTON_CONDITIONS.include?(condition)
    logger.warn("bootstrap_button called with invalid condition #{condition} from #{caller[1]}")
    nil
  end

  BOOTSTRAP_BUTTON_SIZES = {mini: :mini, small: :small, large: :large}

  def bootstrap_button_size(size)
    return nil if size.blank?
    return BOOTSTRAP_BUTTON_SIZES[size] if BOOTSTRAP_BUTTON_SIZES.include?(size)
    logger.warn("bootstrap_button called with invalid size #{size} from #{caller[1]}")
    nil
  end

  BOOTSTRAP_BUTTON_ACTION_TYPES = {transactional: :transactional, curatorial: :curatorial,
                                   social: :social, system: :system}
  def bootstrap_button_action_type(type)
    return nil if type.blank?
    return BOOTSTRAP_BUTTON_ACTION_TYPES[type] if BOOTSTRAP_BUTTON_ACTION_TYPES.include?(type)
    logger.warn("bootstrap_button called with invalid action_type #{type} from #{caller[1]}")
    nil
  end

  # Render a bootstrap button:
  # http://twitter.github.com/bootstrap/components.html#buttonGroups
  #
  # Buttons can be customized heavily.
  # @option options [Symbol] action_type (+nil+) Gives the button the
  #   look and feel of a particular class of buttons in the application.
  #   Current action_types include  :transactional, :curatorial, :social
  #   and :system.
  # @option options [Symbol] size (+nil+) Set the size of the button.
  #   Current valid sizes include :large, :small and :mini.
  def bootstrap_button(*args, &block)
    options = args.extract_options!

    icon = options.delete(:icon)
    inverted_icon = options.delete(:inverted_icon)
    type = options.delete(:type) || :link

    base_classes = ['btn']
    selected_condition = bootstrap_button_condition(options.delete(:condition))
    base_classes << "btn-#{selected_condition}" if selected_condition
    selected_size = bootstrap_button_size(options.delete(:size))
    base_classes << "btn-#{selected_size}" if selected_size
    base_classes << 'active' if options.delete(:active)
    base_classes << bootstrap_button_action_type(options.delete(:action_type))
    base_classes << 'actioned' if options.delete(:actioned)

    html_data = options.delete(:data) || {}

    # don't delete - needs to pass through for ujs
    if options[:remote] == :multi
      options[:remote] = true
      html_data[:link] = 'multi-remote'
    elsif options[:remote]
      html_data[:link] = 'remote'
    end

    modal = options.delete(:toggle_modal)
    if modal
      html_data[:toggle] = :modal
      html_data[:target] = "##{modal}-modal"
    end

    html_options = bootstrap_html_options(options.merge(data: html_data, base_class: base_classes.join(' ')))

    text = if block_given?
      capture { yield }
    elsif type.in?([:button, :submit]) || args.length > 1
      args.shift
    else
      nil
    end
    text = bootstrap_icon(icon, text, options.merge(inverted_icon: inverted_icon)) if icon

    case type
    when :button
      button_tag(text, html_options.merge(type: 'button'))
    when :submit
      button_tag(text, html_options.merge(type: 'submit'))
    else
      link_to(text, *(args << html_options))
    end
  end

  def bootstrap_label(level = :default, text = nil, options = {}, &block)
    options[:class] = "#{options.delete(:class)} label".strip
    options[:class] << " label-#{level}" unless level == :default
    content_tag :span, text, options, &block
  end

  def bootstrap_badge(text = nil, options = {}, &block)
    options = options.dup
    classes = %w(badge)
    level = options.delete(:level)
    classes << "badge-#{level}" if level.present?
    options = bootstrap_html_options(options.merge(base_class: class_attribute(classes)))
    content_tag(:span, text, options, &block)
  end

  def bootstrap_table(options = {}, &block)
    base_classes = ['table']
    base_classes << 'table-condensed' if options.delete(:condensed)
    html_options = bootstrap_html_options(options.merge(base_class: base_classes.join(' ')))
    content_tag :table, html_options do
      yield
    end
  end

  def bootstrap_form_tag(*args, &block)
    options = args.extract_options!
    selected_layout = nil
    [:vertical, :horizontal, :search, :inline].each do |layout|
      (selected_layout ||= layout) if options.delete(layout)
    end
    options[:base_class] = "form-#{selected_layout}" if selected_layout
    options = bootstrap_html_options(options)
    form_tag(*(args << options), &block)
  end

  def bootstrap_text_field_tag(attribute, *args, &block)
    options  = args.extract_options!
    label    = args.first.nil? ? '' : args.shift
    bootstrap_control_group(attribute) do
      out = ''.html_safe
      out << bootstrap_control_label(attribute, label) if label.present?
      out << bootstrap_controls do
        out2 = ''.html_safe
        out2 << text_field_tag(attribute, *(args << options))
        out2 << block.call if block.present?
        out2
      end
      out
    end
  end

  def bootstrap_control_group(*args, &block)
    options = bootstrap_html_options args.extract_options!.merge(base_class: 'control-group')
    content_tag :div, *(args << options), &block
  end

  def bootstrap_control_label(*args, &block)
    options = bootstrap_html_options args.extract_options!.merge(base_class: 'control-label')
    label_tag *(args << options), &block
  end

  def bootstrap_controls(*args, &block)
    options = bootstrap_html_options args.extract_options!.merge(base_class: 'controls')
    content_tag :div, *(args << options), &block
  end

  def bootstrap_check_box_tag(name, text, value = "1", checked = false, options = {})
    base_class = ['checkbox']
    base_class << 'inline' if options.delete(:inline)
    content_tag :label, :class => base_class.join(' ') do
      out = ''.html_safe
      out << check_box_tag(name, value, checked, options)
      out << text
      out
    end
  end

  def bootstrap_radio_button_tag(name, text, value, checked = false, options = {})
    base_class = ['radio']
    base_class << 'inline' if options.delete(:inline)
    content_tag :label, :class => base_class.join(' ') do
      out = ''.html_safe
      out << radio_button_tag(name, value, checked, options)
      out << label_tag("#{name}_#{value}", text)
      out
    end
  end

  def bootstrap_submit_tag(value = 'Save changes', options = {})
    html_options = bootstrap_html_options(options.reverse_merge(base_class:'btn btn-primary'))
    submit_tag value, html_options
  end

  def bootstrap_form_for(*args, &block)
    options = args.extract_options!
    options[:html] ||= {}
    selected_layout = nil
    [:vertical, :horizontal, :search, :inline].each do |layout|
      (selected_layout ||= layout) if options.delete(layout)
    end
    options[:base_class] = "form-#{selected_layout}" if selected_layout
    options = bootstrap_html_options(options)
    options[:html][:class] = options.delete(:class) if options[:class]
    options[:builder] = BootstrapFormBuilder
    form_for(*(args << options), &block)
  end

  def bootstrap_paginate(collection, options = {})
    paginate collection, options.merge(theme: :bootstrap)
  end

  def bootstrap_breadcrumb(items, options = {})
    ul_options = bootstrap_html_options(options.merge(base_class: 'breadcrumb'))
    content_tag(:ul, ul_options) do
      bootstrap_list_items(items, divider: true)
    end
  end

  def bootstrap_modal(id, header, options = {}, &block)
    options = options.reverse_merge(
      show_save: true,
      show_close: true,
      hidden: true,
      show_header: true,
      show_footer: true
    )
    classes = options.fetch(:class, '').split(/\s+/)
    classes << 'modal'
    modal_options = {
      data: (options.delete(:data) || {})
    }
    modal_options[:id] = "#{id}-modal" if id
    classes << 'remotemodal' if options[:remote]
    # it's tempting to use data-show: false for hidden modals, but that actually causes hide() to be called on the
    # modal when it's initialized as the result of a toggle click. so if somebody really wants to use it, they can pass
    # options[:data][:show] in manually.
    modal_options[:style] = 'display:none' if options[:hidden]
    modal_options[:data][:'content-url'] = options[:'content_url'] if options[:'content_url']
    modal_options[:data][:refresh] = options[:refresh] if options[:refresh]
    modal_options[:data].merge!(keyboard: false, backdrop: 'static') if options[:never_close]
    modal_options[:class] = classes.join(' ')
    content_tag(:div, modal_options) do
      out = ''.html_safe
      if options[:show_header]
        out << content_tag(:div, class: 'modal-header') do
          out2 = []
          unless options[:never_close]
            out2 << content_tag(:a, '', class: 'close-button pull-right', data: {dismiss: 'modal'})
          end
          if options[:show_success]
            out2 << content_tag(:i, '', class: 'success-icon')
          end
          out2 << content_tag(:h1, header, data: {role: 'modal-title'})
          out2 << dot_spinner
          safe_join(out2)
        end
      end
      body_classes = %w(modal-body)
      body_classes << 'scrollable' if options[:scrollable_body]
      out << content_tag(:div, class: class_attribute(body_classes)) do
        out2 = ''.html_safe
        out2 << bootstrap_alert(style: 'display:none')
        out2 << content_tag(:div, data: {role: 'modal-content'}, &block)
        out2
      end
      if options[:show_footer]
        out << content_tag(:div, class: 'modal-footer') do
          out2 = ''.html_safe
          if options[:mode] == :admin
            out2 << content_tag(:div, class: 'pull-right') do
              out3 = []
              out3 << bootstrap_modal_save_admin(options) if options[:show_save]
              out3 << bootstrap_modal_close_admin(options) if options[:show_close]
              safe_join(out3)
            end
          else
            out2 << bootstrap_modal_save(options) if options[:show_save]
            out2 << bootstrap_modal_close(options) if options[:show_close]
            out2 << options[:custom_links] if options[:custom_links]
          end
          out2
        end
      end
      out
    end
  end

  def bootstrap_modal_save_admin(options = {})
    bootstrap_button(options.fetch(:save_button_text, 'Save'), condition: :primary, data: {save: 'modal'}, type: :button)
  end

  def bootstrap_modal_close_admin(options = {})
    bootstrap_button(options.fetch(:close_button_text, 'Close'), data: {dismiss: 'modal'}, type: :button)
  end

  def bootstrap_modal_save(options = {})
    button_tag(options.fetch(:save_button_text, 'Save'), data: {save: 'modal'}, type: 'button',
               class: 'btn primary large')
  end

  def bootstrap_modal_close(options = {})
    button_tag(options.fetch(:close_button_text, 'Close'), data: {dismiss: 'modal'}, type: 'button', class: 'btn margin-left')
  end

  def bootstrap_alert(options = {}, &block)
    base_classes = ['alert']
    close = options.delete(:close)
    heading = options.delete(:heading)
    base_classes << 'alert-block' if options.delete(:block)
    selected_level = nil
    [:error, :success, :info].each do |level|
      (selected_level ||= level) if options.delete(level)
    end
    base_classes << "alert-#{selected_level}" if selected_level
    data = options[:data] || {}
    options[:data] = data.reverse_merge(role: :alert)
    html_options = bootstrap_html_options(options.merge(base_class: base_classes.join(' ')))
    content_tag :div, html_options do
      out = ''.html_safe
      out << content_tag(:a, '&times;'.html_safe, class: 'close', data: {dismiss: 'alert'}) if close
      out << content_tag(:h4, heading, class: 'alert-heading') if heading.present?
      out << capture { yield } if block_given?
      out
    end
  end

  def bootstrap_flash(level, text, options = {}, &block)
    options.reverse_merge!({level: level, success: true, close: false, block: true, data: {role: "flash-#{level}"}})
    bootstrap_alert(options) do
      text || yield
    end
  end

  def bootstrap_progress_bar(percent, options = {})
    base_classes = ['progress']
    base_classes << 'progress-striped' if options.delete(:striped)
    base_classes << 'active' if options.delete(:active)
    html_options = bootstrap_html_options(options.merge(base_class: base_classes.join(' ')))
    content_tag(:div, html_options) do
      content_tag(:div, nil, class: 'bar', style: "width: #{percent}%")
    end
  end

  def bootstrap_accordion(options = {}, &block)
    html_options = bootstrap_html_options(options.merge(base_class: 'accordion'))
    content_tag(:div, html_options, &block)
  end

  def bootstrap_accordion_group(options = {}, &block)
    html_options = bootstrap_html_options(options.merge(base_class: 'accordion-group'))
    content_tag(:div, html_options, &block)
  end

  def bootstrap_accordion_heading(parent_selector, target_anchor, *args, &block)
    options = args.extract_options!
    text = args.shift if args.any?
    link_options = options.delete(:link) || {}
    html_options = bootstrap_html_options(options.merge(base_class: 'accordion-heading'))
    content_tag(:div, html_options) do
      link_options = bootstrap_html_options(link_options.merge(base_class: 'accordion-toggle'))
      link_options[:data] ||= {}
      link_options[:data][:toggle] = :collapse
      link_options[:parent] = parent_selector
      link_args = ["##{target_anchor}", link_options]
      link_args.unshift(text) if text.present?
      link_to(*link_args, &block)
    end
  end

  def bootstrap_accordion_body(*args, &block)
    options = args.extract_options!
    selected = args.any?? args.shift : false
    base_classes = ['accordion-body', 'collapse']
    base_classes << 'in' if selected
    inner_options = options.delete(:inner) || {}
    html_options = bootstrap_html_options(options.merge(base_class: base_classes.join(' ')))
    inner_html_options = bootstrap_html_options(inner_options.merge(base_class: 'accordion-inner'))
    content_tag(:div, html_options) do
      content_tag(:div, inner_html_options, &block)
    end
  end

  def bootstrap_image_tag(image_path, type, options)
    image_tag(image_path, options.merge(class: "#{options.class} img-#{type}"))
  end
end

# total rip-off of https://github.com/stouset/twitter_bootstrap_form_for
class BootstrapFormBuilder < ActionView::Helpers::FormBuilder
  attr_reader :template
  attr_reader :object
  attr_reader :object_name

  INPUTS = [
    :select,
    *ActionView::Helpers::FormBuilder.instance_methods.grep(%r{
      _(area|field|select)$ # all area, field, and select methods
    }mx).map(&:to_sym)
  ]

  INPUTS.delete(:hidden_field)

  TOGGLES = [
    :check_box,
    :radio_button,
  ]

  def inline(&block)
    template.fields_for object_name, object, options.merge(builder: ActionView::Helpers::FormBuilder), &block
  end

  def submit(value = 'Save changes', options = {})
    options = options.reverse_merge(base_class: 'btn btn-primary', data: {:'disable-with' => 'Saving…'})
    html_options = template.bootstrap_html_options(options)
    @template.submit_tag(value, html_options)
  end

  def cancel(*args, &block)
    text = if block_given?
      capture { yield }
    else
      'Cancel'
    end
    @template.bootstrap_button(text, *args)
  end

  def help(*args, &block)
    options = args.extract_options!
    if options.delete(:inline)
      base_class = 'help-inline'
      tag = :span
    else
      base_class = 'help-block'
      tag = :div
    end
    html_options = @template.bootstrap_html_options(options.merge(base_class: base_class))
    @template.content_tag(tag, *(args << html_options), &block)
  end

  INPUTS.each do |input|
    define_method input do |attribute, *args, &block|
      options  = args.extract_options!
      label    = args.first.nil? ? '' : args.shift
      append   = options.delete(:append)
      prepend  = options.delete(:prepend)
      buttons  = options.delete(:buttons) || options.delete(:button)

      control_group(attribute) do
        template.concat control_label(attribute, label) if label.present?
        template.concat controls {
          content = super(attribute, *(args << options))
          if append.present? || prepend.present? || buttons.present?
            template.concat append_prepend_wrapper(content, append: append, prepend: prepend, buttons: buttons)
          else
            template.concat content
          end
          template.concat error_span(attribute)
          template.concat help_block(options, &block) if block.present?
        }
      end
    end
  end

  TOGGLES.each do |toggle|
    define_method toggle do |attribute, *args, &block|
      label       = args.first.nil? ? '' : args.shift
      target      = self.object_name.to_s + '_' + attribute.to_s
      label_attrs = toggle == :check_box ? { :for => target } : {}

      case toggle
      when :check_box then label_attrs[:class] = 'checkbox'
      when :radio_button then label_attrs[:class] = 'radio'
      end

      template.content_tag(:label, label_attrs) {
        template.concat super(attribute, *args)
        template.concat label if label
      }
    end
  end

  def toggle_group(attribute, *args, &block)
    options = args.extract_options!
    label = args.first.nil? ? '' : args.shift

    control_group(attribute) do
      template.concat control_label(attribute, label) if label.present?
      template.concat controls {
        template.concat error_span(attribute)
        yield
      }
    end
  end

  def control_group(attribute = nil, options = {}, &block)
    div_wrapper attribute, options.merge(:class => 'control-group'), &block
  end

  def control_label(attribute, text)
    label(attribute, text, :class => 'control-label')
  end

  def controls(attribute = nil, options = {}, &block)
    div_wrapper attribute, options.merge(:class => 'controls'), &block
  end

  def append_prepend_wrapper(content, options = {}, &block)
    append = options.delete(:append)
    prepend = options.delete(:prepend)
    buttons = options.delete(:buttons)
    classes = []
    classes << 'input-append' if append.present? || buttons.present?
    classes << 'input-prepend' if prepend.present?
    div_wrapper nil, options.merge(:class => classes.join(' ')) do
      template.concat template.content_tag(:span, prepend, class: 'add-on') if prepend.present?
      template.concat content
      template.concat template.content_tag(:span, append, class: 'add-on') if append.present?
      template.concat buttons if buttons.present?
    end
  end

  def fields_for(record, *args, &block)
    options = args.extract_options!
    options[:builder] = self.class
    super(record, *(args << options), &block)
  end

  def help_block(options = {}, &block)
    element = options[:help] == :span ? :span : :div
    template.content_tag(element, class: 'help-block', &block)
  end

  protected

    #
    # Wraps the contents of +block+ inside a +tag+ with an appropriate class and
    # id for the object's +attribute+. HTML options can be overridden by passing
    # an +options+ hash.
    #
    def div_wrapper(attribute, options = {}, &block)
      options[:id]    = _wrapper_id      attribute, options[:id]     if attribute
      options[:class] = _wrapper_classes attribute, options[:class]  if attribute

      template.content_tag :div, options, &block
    end

    def error_span(attribute, options = {})
      options[:class] ||= 'help-inline'

      template.content_tag(
        :span, self.errors_for(attribute),
        :class => options[:class]
      ) if self.errors_on?(attribute)
    end

    def errors_on?(attribute)
      self.object.errors[attribute].present? if self.object.respond_to?(:errors)
    end

    def errors_for(attribute)
      self.object.errors[attribute].try(:join, ', ')
    end

    private

    #
    # Returns an HTML id to uniquely identify the markup around an input field.
    # If a +default+ is provided, it uses that one instead.
    #
    def _wrapper_id(attribute, default = nil)
      default || [
        _object_name + _object_index,
        _attribute_name(attribute),
        'input'
       ].join('_')
    end

    #
    # Returns any classes necessary for the wrapper div around fields for
    # +attribute+, such as 'errors' if any errors are present on the attribute.
    # This merges any +classes+ passed in.
    #
    def _wrapper_classes(attribute, *classes)
      classes.compact.tap do |klasses|
        klasses.push 'error' if self.errors_on?(attribute)
      end.join(' ')
    end

    def _attribute_name(attribute)
      attribute.to_s.gsub(/[\?\/\-]$/, '')
    end

    def _object_name
      self.object_name.to_s.gsub(/\]\[|[^-a-zA-Z0-9:.]/, "_").sub(/_$/, "")
    end

    def _object_index
      case
        when options.has_key?(:index) then options[:index]
        when defined?(@auto_index)    then @auto_index
        else                               nil
      end.to_s
    end
end
