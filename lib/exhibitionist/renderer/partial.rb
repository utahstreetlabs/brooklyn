require 'active_support/concern'
require 'active_support/core_ext/class/attribute'
require 'exhibitionist/renderer'

module Exhibitionist
  # Renders an exhibit by rendering a Rails partial.
  class PartialRenderer < Renderer

    # Uses the context's +#capture+ and +#render+ methods to render +partial+ with +locals+ bound into the local
    # scope.
    def do_render(partial, locals = {})
      context.capture { context.render(partial, locals) }
    end
  end

  # Included into exhibits that are rendered with +Exhibitionist::PartialRenderer+.
  #
  # Expects the including exhibit to implement the following methods:
  #
  # * +#locals+: a hash of variable names to values to bind into the local scope of the partial
  #
  # Also expects the including exhibit to declare the partial to render with +#set_partial+.
  module RenderedWithPartial
    extend ActiveSupport::Concern

    included do
      class_attribute :partial
    end

    def render
      partial or
        raise ArgumentError.new("An exhibit rendered with a partial must declare the partial with #set_partial.")
      PartialRenderer.new(context).render(partial, options.merge(locals))
    end

    module ClassMethods
      def set_partial(val)
        self.partial = val
      end
    end
  end
end
