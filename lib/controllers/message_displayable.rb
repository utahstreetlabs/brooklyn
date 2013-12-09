module Controllers
  # Allows a controller to control the display of persistent (non-flash) messages.
  #
  # Messages are displayed in the message box. Each message is uniquely identified by a key. The content of the message
  # comes from the +/shared/messages/:key+ partial.
  #
  # A controller can indicate that a message should be shown on every participating action until cleared by calling
  # +#save_messages+. The controller can indicate that the conditions for showing the message no longer exist by
  # calling +#clear_messages+.
  #
  # A controller can declare that a action participates in messaging (ie wants a particular message to be displayed)
  # with the +show_messages+ macro.
  module MessageDisplayable
    extend ActiveSupport::Concern

    included do
      class_eval <<-EOT
        helper_method :show_message?
        before_filter :initialize_messages
      EOT
    end

    module ClassMethods
      # Declares which messages are shown for this controller's actions.
      #
      # Examples:
      #
      #   show_messages :join_box, only: [:show, :browse]
      #   show_messages :upsell
      def show_messages(*keys)
        options = keys.extract_options!
        before_filter options do
          show_messages(*keys)
        end
      end

      def skip_messaging
        skip_filter :initialize_messages
      end
    end

    module InstanceMethods
    protected
      # Returns true if the specified message is to be shown for this action.
      def show_message?(key)
        @show_messages.include?(key)
      end

      # Indicates that the specified messages are to be shown for this action. Mainly useful when specific logic is
      # needed within an action method to determine whether or not to show a message.
      def show_messages(*keys)
        @show_messages.merge(keys)
      end

      # Causes the specified messages to be persisted in the session.
      def save_messages(*keys)
        session[:messages].merge(keys)
      end

      # Causes the specified messages to be cleared from the session.
      def clear_messages(*keys)
        keys.each {|key| session[:messages].delete(key)}
      end

    private
      def initialize_messages
        session[:messages] ||= Set.new
        @show_messages = Set.new
      end
    end
  end
end
