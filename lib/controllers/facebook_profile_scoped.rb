module Controllers
  # Provides common behaviors for controllers that are scoped to a Facebook profile or require Facebook connection.
  module FacebookProfileScoped
    extend ActiveSupport::Concern

    module ClassMethods
    protected
      def set_facebook_profile(options = {})
        before_filter(options) do
          @fb_profile = current_user.person.for_network(:facebook)
          unless @fb_profile
            logger.warn("Disallowing as user does not have a Facebook profile")
            respond_unauthorized
          end
        end
      end

      def require_facebook_connection(options = {})
        before_filter(options) do
          unless current_user.person.connected_to?(:facebook)
            logger.warn("Disallowing as user is not connected to Facebook")
            respond_unauthorized
          end
        end
      end

      def load_friend_boxes(options = {})
        before_filter(options) do
          @friend_boxes = ::Invites::FacebookDirectShareContext.eligible_profiles(current_user, renderer: self, name: params[:name])
        end
      end
    end
  end
end
