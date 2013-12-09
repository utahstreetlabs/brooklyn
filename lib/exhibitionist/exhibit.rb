require 'exhibitionist/logging'

module Exhibitionist
  # An exhibit wraps and delegates to a model object, decorating it with behavior related to rendering a view of the
  # model in a particular context.
  #
  # Subclasses must implement the +#render+ method, generally by mixing in a "rendered with" module provided by a
  # specific renderer.
  class Exhibit < SimpleDelegator
    include Logging
    attr_reader :viewer, :context, :options

    def initialize(exhibited, viewer, context, options = {})
      super(exhibited)
      @viewer = viewer
      @context = context
      @options = options
    end

    def i18n_scope
      key = self.class.name.underscore.gsub(/exhibit\z/, '').gsub(/_/, '.')
      "exhibits.#{key}"
    end

    def render
      raise NotImplementedError.new("An exhibit must implement the render method.")
    end
  end
end
