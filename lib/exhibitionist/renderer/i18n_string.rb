require 'active_support/concern'
require 'exhibitionist/renderer'

module Exhibitionist
  # Renders an exhibit by translating a localized message.
  class I18nStringRenderer < Renderer

    # Uses the context's +#t+ method to translate the localized message identified by +key+ in the given +scope+
    # parameterized with +params+.
    def do_render(key, scope, params)
      context.t(key, params.merge(scope: scope))
    end
  end

  # Included into exhibits that are rendered with +Exhibitionist::I18nStringRenderer+.
  #
  # Expects the including exhibit to implement the following methods:
  #
  # * +#i18n_key+: returns the key for the message
  # * +#i18n_scope+: returns the scope for the message
  # * +#i18n_params+: returns the parameters for the message
  module RenderedWithI18nString
    extend ActiveSupport::Concern

    def render
      I18nStringRenderer.new(context).render(i18n_key, i18n_scope, i18n_params)
    end
  end
end
