require 'active_support/concern'

module Controllers
  # A concern that allows a controller to communicate to the next page that an event occurred triggering the display
  # of some conditional element.
  #
  # DEPRECATED in favor of using the built-in flash mechanism.
  module DisplayRequestable
    extend ActiveSupport::Concern

    included do
      class_eval <<-EOT
        helper_method :display_requested?
      EOT
    end

    module InstanceMethods
    protected
      # Request that content associated with this key or set of keys be displayed at the next available opportunity.:w
      def request_display(*keys)
        @display_requests ||= (session[:display_requests] || Set.new)
        session[:display_requests] = @display_requests = @display_requests | keys
      end

      # Check if there is currently a request to display content based on the provided key
      # Removes the key from the session, but if found will respond with a positive throughout the request
      def display_requested?(key)
        @display_requests ||= (session[:display_requests] ||= Set.new).dup
        session[:display_requests].delete(key)
        # allow simple dev by passing the key in a query string
        @display_requests.member?(key) || params[key]
      end
    end
  end
end
