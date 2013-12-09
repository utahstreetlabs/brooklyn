module AdminHelper
  def add_button_tag(text)
    image_tag('icons/add.png', :alt => '+', :title => text)
  end

  def link_to_add(text, url, options = {})
    link_to text, url, options.merge(class: 'add button left positive')
  end

  def edit_button_tag
    image_tag('icons/edit.png', :alt => '...', :title => 'edit')
  end

  def link_to_edit(url, options = {})
    link_to(edit_button_tag, url, options.merge(:title => 'edit'))
  end

  def delete_button_tag
    image_tag('icons/delete.png', :alt => 'X', :title => 'remove')
  end

  def link_to_delete(url, options = {})
    ActiveSupport::Deprecation.warn("link_to_delete is deprecated")
    link_to(delete_button_tag, url, options.merge(:method => :delete, :title => 'remove',
      :'data-confirm' => 'Are you sure?'))
  end

  def admin_notice(type, text = nil)
    bootstrap_flash(:notice, text, close: true)
  end

  def admin_alert(type, text = nil, &block)
    bootstrap_flash(:alert, text, close: true)
  end

  def admin_toggle_button(name, state, on_options, off_options, options = {})
    data_options = {remote: true, link: :remote, format: :json}
    on_options[:style] = 'display:none' if state
    on_options[:rel] = :tooltip if on_options[:title]
    on_options[:icon] = options[:icon] if options[:icon]
    on_options[:data] = data_options.dup
    on_options[:data][:action] = "#{name}-on"
    on_options[:data][:method] = on_options.delete(:method) || :put
    on_url = on_options.delete(:url)
    off_options[:style] = 'display:none' unless state
    off_options[:rel] = :tooltip if off_options[:title]
    off_options[:icon] = options[:icon] if options[:icon]
    off_options[:data] = data_options.dup
    off_options[:data][:action] = "#{name}-off"
    off_options[:data][:method] = off_options.delete(:method) || :delete
    off_url = off_options.delete(:url)
    bootstrap_button(on_url, on_options) + bootstrap_button(off_url, off_options)
  end

  def annotation_table_row(annotation)
    annotatable = annotation.annotatable
    content_tag :tr do
      contents = []
      contents << content_tag(:td) do
        link_to(annotation.url, annotation.url, {data: {role: 'annotation', annotation: annotation.id}})
      end
      contents << content_tag(:td) do
        bootstrap_button(nil, send("admin_#{annotatable.class.name.underscore}_annotation_path", annotatable.id, annotation.id),
          condition: :danger, size: :mini, icon: :remove, inverted_icon: true, rel: :tooltip, title: "Remove annotation",
          data: {method: :delete, confirm: 'Are you sure you want to remove this support link?', action: 'remove-annotation'})
      end
      contents.join.html_safe
    end
  end

  def annotations_list(annotatable)
    bootstrap_table condensed: true do
      annotatable.annotations.map do |annotation|
        annotation_table_row(annotation)
      end.join.html_safe
    end
  end

  def form_for_new_annotation(annotatable, &block)
    type = annotatable.class.name.underscore
    url = send("admin_#{type}_annotations_path", annotatable.id)
    bootstrap_form_for(Annotation.new, url: url, &block)
  end
end
