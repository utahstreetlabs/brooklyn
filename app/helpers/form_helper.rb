module FormHelper
  def fieldset(options = {}, &block)
    text = ''
    text << content_tag(:legend, options.delete(:legend)) if options[:legend].present?
    text << content_tag(:div, options.delete(:div), :class => 'legend') if options[:div].present?
    text << content_tag(:ol, &block)
    content_tag(:fieldset, text.html_safe, options)
  end

  # @option options [Object] :error if present, specifies "right-side" error messaging (if a Hash, interpeted as html
  #   options for the error message container), otherwise specifies "below" error messaging
  #
  # Examples:
  #
  #   field(:name) do
  #     text_field :name
  #   end
  #
  #   # bottom error messaging
  #   field(:name, errors: ['is required'])
  #     text_field :name
  #   end
  #
  #   # right-side error messaging
  #   field(:name, errors: ['is required'], error: true)
  #     text_field :name
  #   end
  #
  #   # right-side error messaging with options
  #   field(:name, errors: ['is required'], error: {class: 'span5'})
  #     text_field :name
  #   end
  def field(name, options = {}, &block)
    text = capture(&block) if block_given?
    css_classes = Set.new((options.delete(:class) || '').split(/\s+/))
    errors = options.delete(:errors)
    error_options = options.delete(:error)
    error_options = {} if error_options && !error_options.is_a?(Hash)
    if errors && !errors.empty?
      css_classes << 'error'
      text << error_messages(errors, error_options)
    end
    help = options.delete(:help)
    if help
      help_classes = 'help_text '
      help_classes << help[:class] if help[:class]
      text << content_tag(:span, help[:text], class: help_classes.strip)
    end
    css_classes << "field-#{name}"
    html_options = {:id => "field_#{name}"}
    html_options[:class] = css_classes.to_a.join(' ') unless css_classes.empty?
    container = options.delete(:container) || :li
    content_tag(container, text, html_options.merge(options))
  end

  def label_tag(name, text = nil, options = {}, &block)
    if text.is_a?(Hash)
      options = text
      text = nil
    end
    out = []
    out << (text || name.to_s.titleize)
    out << help_text(options[:help].html_safe) if options[:help].present?
    super(name, out.join(' ').html_safe, options, &block)
  end

  def help_text(text = nil, &block)
    content_tag(:em, text, :class => 'help_text', &block)
  end

  # @param [Array] errors a list of one or more error messages
  # @param [Hash] options specifies that the most important error message should be displayed to the right of the input
  #   field and provides options for the containing div; if not present, all error messages are displayed below the
  #   input field
  def error_messages(errors, options = nil)
    if options
      # this design does not support multiple errors for a single field
      options[:class] ||= ''
      options[:class] << ' errorlist inline-block-element pull-left'
      options[:class].strip
      content_tag(:div, errors.first, options)
    else
      content_tag(:ul, safe_join(errors.map { |e| content_tag(:li, e) }), :class => 'errorlist')
    end
  end

  def error_messages_on(object, method)
    error_messages(object.errors[method])
  end

  def buttons(options = {}, &block)
    css_class = 'buttons '
    css_class << (options.delete(:bigger) ? 'bigger_buttons ' : '')
    content_tag(:div, :class => css_class ) do
      if block_given?
        yield
      else
        save_text = options.delete(:save_text) || 'Save'
        out = ''.html_safe
        out << save_button_tag(save_text, options)
        if options[:spinner]
          out << content_tag(:span, nil, class: 'loading-spinner', style: 'display:none')
        end
        if options.include?(:cancel_url)
          cancel_url = options.delete(:cancel_url)
          cancel_text = options.delete(:cancel_text) || 'Cancel'
          out << link_to(cancel_text, cancel_url, options.delete(:cancel_options))
        end
        out
      end
    end
  end

  def save_button_tag(text, options = {})
    tag_options = {:type => 'submit', :class => options.delete(:class) || 'button primary clear large', data: {}}
    unless options.delete(:no_disable)
      tag_options[:data][:'disable-with'] = options.delete(:disable_with) || 'Submitting ...'
    end
    action = options.delete(:action)
    tag_options[:data][:action] = action if action
    text = options[:save_image].present?? image_and_text(options.delete(:save_image), text) : text
    content_tag(:button, text, tag_options.merge(options))
  end
end
