module Controllers
  # Provides common behaviors for controllers that are scoped to an Instagram profile or require Instagram connection.
  module InstagramProfileScoped
    extend ActiveSupport::Concern

    module ClassMethods
    protected
      def set_instagram_profile(options = {})
        before_filter(options) do
          @ig_profile = current_user.person.for_network(:instagram)
          unless @ig_profile
            logger.warn("Disallowing as user does not have a Instagram profile")
            respond_unauthorized
          end
        end
      end

      def require_instagram_connection(options = {})
        before_filter(options) do
          unless current_user.person.connected_to?(:instagram)
            logger.warn("Disallowing as user is not connected to Instagram")
            respond_unauthorized
          end
        end
      end
    end
  end
end
