require 'active_support/concern'

module Controllers
  # Vanity support
  # https://github.com/assaf/vanity
  #
  # Provides methods for setting up the vanity context.
  #
  # requires DoesAnalytics concern
  module ABTestable
    extend ActiveSupport::Concern
    include DoesAnalytics

    included do
      set_vanity_identity
    end

    def vanity_id_from_url
      request.get? && params[:_identity]
    end

    def vanity_context(id = nil)
      id || vanity_id_from_url || visitor_identity
    end

    module ClassMethods

      # Tie together Vanity's use_vanity method and our
      # visitor_identity logic. use_vanity expects either an object
      # with an #id method or a block that returns a string - we're
      # using the latter.
      def set_vanity_identity
        use_vanity { |c| c.vanity_context }
      end
    end
  end
end
