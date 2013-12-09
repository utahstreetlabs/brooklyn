require 'active_support/concern'

module Users
  # Provides a facility similar to ActionPack's session-based flash messaging but that is accessible to all application
  # components, even those running in background jobs. The +top_message+ hash is backed by Redis.
  #
  # @see TopMessage
  module TopMessaging
    extend ActiveSupport::Concern
    include Ladon::ErrorHandling

    included do
      hash_key :top_message
    end

    def add_top_message(msg)
      self.class.with_error_handling('Adding top message', key: msg.key) do
        top_message[msg.key] = msg.to_s
      end
    end

    def get_top_message(key)
      self.class.with_error_handling('Getting top message', key: key) do
        value = top_message[key]
        value && TopMessage.decode(key, value)
      end
    end

    def delete_top_message(key)
      self.class.with_error_handling('Deleting top message', key: key) do
        top_message.delete(key)
      end
    end

    def top_messages
      self.class.with_error_handling('Getting top messages') do
        top_message.map { |key, value| TopMessage.decode(key, top_message[key]) }
      end
    end

    def clear_top_messages
      self.class.with_error_handling('Clearing top messages') do
        top_message.clear
      end
    end
  end
end
