require 'exhibitionist/logging'

module Exhibitionist
  # A renderer generates a view of an exhibit in a context using some underlying rendering mechanism (e.g. translating
  # a localized message or rendering a Rails partial).
  #
  # Subclasses must implement the +#render+ method.
  class Renderer
    include Logging

    attr_reader :context, :options, :virtual_path

    # @option options [String] :virtual_path if present, sets the context's +@virtual_path+ instance variable while
    # rendering (resetting it to the original value after rendering). This is necessary if the renderer calls
    # +context.t+ with a shortcut key (e.g. +.foo.bar+).
    def initialize(context, options = {})
      @context = context
      @options = options
      @virtual_path = options[:virtual_path]
    end

    def render(*args)
      if options[:virtual_path].present?
        original_virtual_path = @context.instance_variable_get(:@virtual_path)
        @context.instance_variable_set(:@virtual_path, options[:virtual_path])
      end
      rv = do_render(*args)
      if options[:virtual_path].present?
        @context.instance_variable_set(:@virtual_path, original_virtual_path)
      end
      rv
    end

    def do_render(*)
      raise NotImplementedError.new("A renderer must implement the do_render method.")
    end
  end
end
