require 'active_support/concern'
require 'active_support/core_ext/class/attribute'
require 'exhibitionist/renderer'

module Exhibitionist
  # Renders an exhibit by allowing the exhibit to define its own rendering. The exhibit specifies a custom rendering
  # function that is called at rendering time in the context of the renderer's +context+, yielding the exhibit itself
  # to the custom rendering function. This allows the exhibit's custom rendering function to be terse and to take
  # advantage of translation shortcuts. For example:
  #
  #   class MyExhibit < Exhibitionist::Exhibit
  #     include Exhibitionist::RenderedWithCustom
  #
  #     custom_render do |my|
  #       link_to('.do_something', do_something_path(foo: my.foo))
  #     end
  #
  #   end
  class CustomRenderer < Renderer
    def do_render(exhibit, viewer, custom_renderer)
      context.instance_exec(exhibit, viewer, &custom_renderer)
    end
  end

  # Included into exhibits that are rendered with +Exhibitionist::CustomRenderer+.
  #
  # Expects the including exhibit to declare a custom rendering function to render with +#custom_renderer+.
  module RenderedWithCustom
    extend ActiveSupport::Concern

    included do
      class_attribute :custom_renderer
    end

    def render
      custom_renderer or
        raise ArgumentError.new("A custom rendered exhibit must declare the rendering function with #custom_render.")
      CustomRenderer.new(context, virtual_path: self.i18n_scope).render(self, viewer, custom_renderer)
    end

    module ClassMethods
      def custom_render(&block)
        self.custom_renderer = block
      end
    end
  end
end
