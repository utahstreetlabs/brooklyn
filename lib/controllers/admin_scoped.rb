require 'active_support/concern'

module Controllers
  # Provides common behaviors for administrative controllers.
  module AdminScoped
    extend ActiveSupport::Concern

    included do
      layout 'admin'
    end
  end
end
