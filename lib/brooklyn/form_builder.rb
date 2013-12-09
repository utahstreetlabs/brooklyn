module Brooklyn
  class FormBuilder < ActionView::Helpers::FormBuilder

    def fieldset(options = {}, &block)
      @template.fieldset(options, &block)
    end

    def field(method, options = {}, &block)
      field_options = {:errors => @object ? @object.errors[method] : []}
      @template.field(method, field_options.merge(options), &block)
    end

    def label(method, text = nil, options = {}, &block)
      out = []
      if text.is_a?(Hash)
        options = text
        out << method.capitalize
      else
        out << text
      end
      out << @template.required_marker if options[:required] == true
      out << @template.help_text(options[:help].html_safe) if options[:help].present?
      super(method, out.join(' ').html_safe, options, &block)
    end

    def buttons(options = {}, &block)
      @template.buttons(options, &block)
    end

    def save_button(*args)
      @template.save_button_tag(*args)
    end
  end
end
