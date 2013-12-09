# encoding: utf-8

module SearchHelper
  def facet_add_link(obj, hash = {}, &block)
    facet_change_link(obj, :add_to_url, hash, &block)
  end

  def facet_remove_link(obj, hash = {}, options = {})
    facet_change_link(obj, :remove_from_url, hash, options.merge(data: { 'action' => 'remove' }))
  end

  def facet_change_url(obj, modifier, hash)
    key = hash[:key] || obj.class.name.tableize.pluralize
    value = hash[:value] || obj.id
    # use fetch because we want to allowing setting it to +nil+ in the hash
    category = hash.fetch(:category, @category)
    # always reset pagination when changing facets
    new_params = self.send(modifier, key.to_s, value.to_s, request.query_parameters.dup).merge(reset_pagination: true)
    browse_for_sale_path_tags_path(category, new_params)
  end

  def facet_change_link(obj, modifier, hash, options = {}, &block)
    path = hash[:url] || facet_change_url(obj, modifier, hash)
    text = (block.call if block) || hash[:text] || obj.name.titleize
    title = hash[:text] || obj.name.titleize
    link_to(text, path, options.merge(data: { role: 'facet-change', title: title }){ |key, first, second| first.merge(second) })
  end

  # Return a hash of query parameters, with the +key+ added if it doesn't
  # exist, or, if it's already in it, it adds it as an array key.
  def add_to_url(key, value, params)
    params.merge(key => (params.fetch(key, []) | [value]))
  end

  # Return a hash of query parameters, but with the +value+ removed from
  # the +key+ array, if it exists.
  def remove_from_url(key, value, params)
    params[key] = params[key].reject { |v| v == value } if params.has_key?(key)
    params.reject { |k,v| v.empty? }
  end

  def obj_name(obj, hash = {})
    content_tag(:span, hash[:text] || obj.name.titleize, class: 'facet-name')
  end

  def facet_count(count)
    ('&nbsp;' + content_tag(:span, count.to_s, class: 'facet-count')).html_safe
  end

  def facet_li(obj, options = {}, &block)
    classes = %w(facet)
    classes << 'selected' if options[:selected]
    content_tag(:li, obj.name, class: class_attribute(classes), &block)
  end

  def facet_checkbox(obj, hash = {})
    selected = hash[:selected] || false
    modifier = selected ? :remove_from_url : :add_to_url
    path = facet_change_url(obj, modifier, hash)
    text = hash[:text] || obj.name.titleize
    facet_li(obj, hash) do
      facet_change_link(obj, modifier, hash) do
        out = check_box_tag(text, hash[:value] || obj.name, selected, data: { role: 'facet-checkbox', url: path })
        out << obj_name(obj, hash)
        out << facet_count(hash[:count])
      end
    end
  end

  def facet_checkboxes(list, options = {}, &block)
    list.map do |obj, selected, count|
      new_hash = { count: count, selected: selected }.merge(options)
      new_hash = new_hash.merge(block.call(obj)) if block_given?
      new_hash[:value] ||= obj.slug
      facet_checkbox(obj, new_hash)
    end
  end

  def condition_checkboxes(list)
    facet_checkboxes(list, key: :conditions) { |dv| { value: dv.id } }
  end

  def price_range_checkboxes(list)
    facet_checkboxes(list, key: :prices) { |o| { text: o.name } }
  end

  def facet_add_li(obj, hash = {})
    facet_li(obj, hash) do
      facet_add_link(obj, hash) { obj_name(obj, hash) + facet_count(hash[:count]) }
    end
  end

  def facet_list_items(list, hash = {}, &block)
    list.map do |obj, selected, count|
      new_hash = hash.merge(selected: selected, count: count)
      new_hash = new_hash.merge(block.call(obj)) if block_given?
      new_hash[:value] ||= obj.slug
      facet_add_li(obj, new_hash)
    end
  end

  def category_list_items(list, hash = {}, &block)
    facet_list_items(list, suppress_key: true) do |category|
      { url: browse_for_sale_path_tags_path(category.slug, request.query_parameters.dup.merge(reset_pagination: true)) }
    end
  end

  def facet_selection(text, obj, value, options = {})
    options = { value: value, text: 'x' }.merge(options)
    content_tag(:span, class: 'tag-interaction', data: { role: 'facet-selection' }) do
      text.html_safe + facet_remove_link(obj, options, class: 'tag-remover')
    end
  end

  def facet_selections(category, searcher)
    selections = category ? [facet_selection(category.name, category, category.slug, category: nil)] : []
    @searcher.tags.selected.each { |t| selections << facet_selection(t.name, t, t.slug, key: :tags) }
    @searcher.price_ranges.selected.each { |p| selections << facet_selection(p.name, p, p.slug, key: :prices) }
    @searcher.sizes.selected.each { |s| selections << facet_selection(s.name, s, s.slug, key: :sizes) }
    @searcher.brands.selected.each { |s| selections << facet_selection(s.name, s, s.slug, key: :brands) }
    @searcher.conditions.selected.each {|v| selections << facet_selection(v.name, v, v.slug, key: :conditions)}
    selections
  end

  def browse_facet_selections(title)
    selections = facet_selections(@category, @searcher)
    attrs = {id: 'selection-container', class: 'tags-container', data: {role: 'search-facet'}}
    if feature_enabled?('horizontal_browse') && selections.empty?
      attrs[:style] = 'display:none;'
    end
    content_tag(:div, attrs) do
      out = []
      out << content_tag(:span, title, class: 'tag-title')
      out << safe_join(selections)
      safe_join(out)
    end
  end

  def sidebar_box(title, options = {}, &block)
    options = options.merge(class: "section #{title.underscore.pluralize} span4", data: {role: 'search-facet'})
    options[:style] = 'display: none;' if options.delete(:hidden)
    content_tag(:div, options) do
      content_tag(:h2, title, class: 'sub-header') + content_tag(:ul, class: "nav nav-vertical-list less-spacing search-facet") do
        block.call
      end
    end
  end

  def single_tag(searcher)
    selected = searcher.tags.selected
    (selected && selected.count == 1) ? Tag.find_by_slug(selected.first.slug) : nil
  end

  def listing_search_browse_title(searcher, tag_name = nil)
    return searcher.query if searcher.query.present?
    return searcher.category.name if searcher.category
    unless tag_name
      single_tag = single_tag(searcher)
      tag_name = single_tag.name.titlecase if single_tag
    end
    return tag_name if tag_name
    return searcher.sort_key == :popular ? 'Most Popular' : 'New Arrivals'
  end

  def listing_search_browse_header(searcher, options = {})
    single_tag = single_tag(searcher)
    tag_name = single_tag && single_tag.name.titlecase
    title = listing_search_browse_title(searcher, tag_name)
    content_tag(:h2, class: 'browse-title') do
      out = []
      out << content_tag(:span, '“', class: 'search-string-wrap')
      out << content_tag(:span, title, id: 'title-container', class: 'category-title')
      out << content_tag(:span, '”', class: 'search-string-wrap')
      out << ' '
      out << content_tag(:span, class: 'result-text') do
        out2 = []
        out2 << 'We found '
        # can't use pluralize(searcher.total, 'item') because we need to wrap a span around the count
        out2 << content_tag(:span, number_with_delimiter(searcher.total), id: 'items-found-number',
          class: 'items-found-number')
        out2 << (searcher.total == 1 ? ' item' : ' items')
        safe_join(out2)
      end
      safe_join(out)
    end
  end

  def listings_sort_links(searcher)
    searcher.sort_keys.map do |key|
      item_options = {}
      link_options = { data: { role: 'facet-change' } }
      if feature_enabled? 'horizontal_browse'
        item_options[:class] = 'selected' if key == searcher.sort_key
      else
        link_options[:class] = 'selected' if key == searcher.sort_key
      end
      path = browse_for_sale_path_tags_path(searcher.category,
        params.merge(tags: searcher.tags.selected.map(&:slug), sort: key, reset_pagination: true))
      content_tag(:li, link_to(t("search_browse.browse.sort.#{key}"), path, link_options).html_safe, item_options)
    end
  end

  def listing_search_browse_banner(searcher, options = {})
    if @searcher.tags.selected.count == 1
      promo_banner(Brooklyn::Application.config.banners.search_browse[@searcher.tags.selected.first.slug], options)
    end
  end

  def facet_title(type, list, options = {})
    # Assume list contains only selected items
    default_title = t("search_browse.browse.#{type}.default")
    selected_count = list.length

    if selected_count == 1
      list.first.name
    elsif selected_count > 1
      "#{options[:name] || default_title} (#{selected_count})"
    else
      default_title
    end
  end

  def browse_tab(type, title, menu_items = [], options = {})
    data = options.fetch(:data, {}).merge(role: 'search-facet')
    options = options.merge(id: "#{type}-container", class: 'browse-tab', data: data)
    bootstrap_dropdown(options) do
      out = []
      out << bootstrap_dropdown_toggle(title, caret: true)
      out << bootstrap_dropdown_menu(menu_items, id: "#{type}-dropdown", class: 'search-facet',
                                     item: { formatted: true })
      safe_join(out)
    end
  end
end
