require 'active_support/concern'

module Controllers
  module TopMessages
    extend ActiveSupport::Concern

    included do
      attr_accessor :top_messages
      helper_method :top_messages
    end

    def load_top_messages
      if current_user
        @top_messages = current_user.top_messages
        current_user.clear_top_messages
        current_user.set_just_registered if session.delete(:signup_just_registered)
      end
    end

    module ClassMethods
      def load_top_messages(options = {})
        before_filter(:load_top_messages, options)
      end

      def skip_loading_top_messages(options = {})
        skip_filter(:load_top_messages, options)
      end
    end
  end
end
