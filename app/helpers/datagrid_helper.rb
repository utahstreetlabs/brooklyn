require 'datagrid/helpers/table'
require 'kaminari'

module DatagridHelper
  def datagrid_search_form
    bootstrap_form_tag('', method: :get, search: true, class: 'datagrid-search') do
      [search_field_tag(:query, params[:query], class: 'search-query'), bootstrap_button('Search', type: :submit)].
        join(' ').html_safe
    end
  end

  def datagrid_total_results(collection, options = {})
    default_name = collection.any? ? collection.first.class.model_name.human.downcase : 'result'
    name = options[:name] || default_name
    content_tag :div do
      if collection.any?
        "#{pluralize(collection.total_count, name)} total"
      else
        pluralize(0, name)
      end
    end
  end

  def datagrid(collection, options = {}, &block)
    table = Datagrid::Table.new(self, collection, params)
    table_html = table.to_s(options.fetch(:html, {}), &block)
    out = []
    out << datagrid_search_form unless options[:disable_search]
    out << paginate(collection, theme: options[:pagination_theme])
    out << datagrid_total_results(collection, name: options[:result_name]) unless options[:disable_total_results]
    if options[:url]
      out << form_tag(options[:url], options.fetch(:form, {})) do
        table_html
      end
    else
      out << table_html
    end
    out << paginate(collection, theme: options[:pagination_theme])
    out << datagrid_total_results(collection, name: options[:result_name]) if
      collection.any? && !options[:disable_total_results]
    out.join("\n").html_safe
  end
end
