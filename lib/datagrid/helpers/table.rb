module Datagrid
  class Table
    def initialize(template, collection, params)
      @template = template
      @collection = collection
      @params = params
    end

    def to_s(html_options = {}, &block)
      @template.content_tag(:table, html_options) do
        yield(self) if block_given?
      end
    end

    def thead(&block)
      th = Datagrid::TableHead.new(@template, @params)
      @template.content_tag :thead do
        yield(th) if block_given?
      end
    end

    def tbody(html_options = {}, &block)
      tb = Datagrid::TableBody.new(@template, @params)
      @template.content_tag :tbody do
        if @collection.any?
          @collection.inject([]) do |memo, model|
            memo << @template.content_tag(:tr, html_options) do
              yield(tb, model) if block_given?
            end
          end.join("\n").html_safe
        end
      end
    end
  end

  class TableHead
    def initialize(template, params)
      @template = template
      @params = params
    end

    def th(column = nil, options = {}, &block)
      if column.present?
        title = options.delete(:title) || column.to_s.titleize
        title = nil if title == :none
        is_default = options.delete(:default) || false
        is_selected = (@params[:sort].blank? && is_default) || (@params[:sort] == column.to_s)
        default_direction = options[:default_direction] || :asc
        is_asc = (@params[:direction].blank? && default_direction == :asc) || @params[:direction] == 'asc'
        direction = is_selected && is_asc ? 'desc' : 'asc'
        css_class = is_selected ? "datagrid-header-selected datagrid-header-#{is_asc ? :asc : :desc}" : nil
        @template.content_tag :th, options do
          if title
            @template.link_to title, @params.merge(sort: column, direction: direction), class: css_class
          end
        end
      else
        @template.content_tag :th, options do
          yield if block_given?
        end
      end
    end

    def toggle(html_options = {})
      th html_options do
        @template.check_box_tag "toggle_all", '1', false, title: 'select/deselect all', class: 'datagrid-toggle-all'
      end
    end

    def actions(html_options = {}, &block)
      th nil, html_options, &block
    end
  end

  class TableBody
    def initialize(template, params)
      @template = template
      @params = params
    end

    def td(html_options = {}, &block)
      @template.content_tag :td, html_options do
        yield if block_given?
      end
    end

    def toggle(model, attr, html_options = {})
      checkbox_options = html_options.delete(:checkbox) || {}
      checkbox_options.reverse_merge!(id: "#{attr}_#{model.send(attr)}", class: 'datagrid-toggle')
      checkbox_options[:disabled] = true if html_options.delete(:disabled)
      checked = html_options.delete(:checked) || false
      td html_options do
        @template.check_box_tag "#{attr}[]", model.send(attr), checked, checkbox_options
      end
    end

    def actions(html_options = {}, &block)
      td html_options, &block
    end
  end
end
