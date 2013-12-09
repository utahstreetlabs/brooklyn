require 'active_support/concern'
require 'active_support/notifications'

module Brooklyn
  # Allows the application to fire arbitrary ActiveSupport notification events.
  module Instrumentation
    extend ActiveSupport::Concern

    def fire_event(name, payload = {}, &block)
      self.class.fire_event(name, payload, &block)
    end

    def fire_user_notification_event(category, payload = {}, &block)
      self.class.fire_user_notification_event(category, payload, &block)
    end

    module ClassMethods
      # Fires an ActiveSupport notification event. If a block is given, the duration of the event is that of the block
      # execution.
      #
      # @param [Symbol] name a name that uniquely identifies this event
      # @param [Hash] payload a flat hash of data to be attached to the event
      # @yield
      def fire_event(name, payload = {}, &block)
        ActiveSupport::Notifications.instrument("#{name}.brooklyn", payload, &block)
      end

      def fire_user_notification_event(category, payload = {}, &block)
        payload[:class] = category
        fire_event(:user_notification, payload, &block)
      end
    end
  end
end
