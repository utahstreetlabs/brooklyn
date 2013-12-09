require 'active_support/concern'
require 'active_support/core_ext/class/attribute'
require 'exhibitionist/renderer'

module Exhibitionist
  # Renders an exhibit by calling a Rails helper.
  class HelperRenderer < Renderer
    # Uses the context's +#capture+ and +#render+ methods to invoke +helper+ passing it +args+.
    def do_render(helper, *args)
      context.send(helper.to_sym, *args)
    end
  end

  # Included into exhibits that are rendered with +Exhibitionist::HelperRenderer+.
  #
  # The including exhibit may implement the following methods:
  #
  # * +#args+: returns an array of arguments to pass when invoking the helper
  #
  # Expects the including exhibit to declare the helper to render with +#set_helper+.
  #
  # The exhibit may also set a virtual path for the renderer using +#set_virtual_path+.
  module RenderedWithHelper
    extend ActiveSupport::Concern

    included do
      class_attribute :helper, :virtual_path
    end

    def render
      helper or
        raise ArgumentError.new("An exhibit rendered with a helper must declare the helper with #set_helper.")
      argz = respond_to?(:args) ? args : []
      HelperRenderer.new(context, virtual_path: virtual_path).render(helper, *argz)
    end

    module ClassMethods
      def set_helper(val)
        self.helper = val
      end

      def set_virtual_path(val)
        self.virtual_path = val
      end
    end
  end
end
