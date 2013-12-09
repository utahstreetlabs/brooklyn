module Controllers
  # Provides common behaviors for controllers that are scoped to a public profile.
  module ProfileScoped
    extend ActiveSupport::Concern

    included do
      helper_method :profile_user, :listings_count, :collections_count, :liked_count, :following_count,
                    :following_collections_count, :following_people_count, :followers_count,
                    :connection_between_viewer_and_profile_user, :results, :likes, :users
    end

    module ClassMethods
      def load_profile_user(options = {})
        before_filter(options) { load_profile_user }
      end

      def require_registered_profile_user(options = {})
        before_filter(options) { require_registered_profile_user }
      end
    end

    module InstanceMethods
      attr_reader :profile_user, :results, :likes, :users

    protected
      def load_profile_user
        @profile_user = User.find_by_slug!(params[:public_profile_id] || params[:id])
      end

      def require_registered_profile_user
        unless profile_user.registered?
          logger.warn("Disallowing request as profile user is not registered")
          respond_not_found
        end
      end

      def listings_count
        @listings_count ||= profile_user.visible_listings_count
      end

      def collections_count
        @collections_count ||= profile_user.collections_count
      end

      def liked_count
        @liked_count ||= profile_user.likes_count
      end

      def following_count
        @following_count ||= following_collections_count + following_people_count
      end

      def following_collections_count
        @following_collections_count ||= profile_user.unowned_collection_follows_count
      end

      def following_people_count
        @following_people_count ||= profile_user.registered_followings.total_count
      end

      def followers_count
        @followers_count ||= profile_user.registered_follows.total_count
      end

      def connection_between_viewer_and_profile_user
        unless anonymous_user? or profile_user == current_user
          @connection ||= SocialConnection.find(current_user, profile_user)
        end
      end

      def results=(listings)
        @results = ListingResults.new(current_user, listings, connections: false)
      end

      def likes=(likes)
        @likes = CardCollection.new(current_user, likes, connections: false, default_tag_liker: profile_user,
          listings_per_card: Brooklyn::Application.config.tags.cards.profile_listing_count)
      end

      def users=(users)
        @users = UserStripCollection.new(current_user, users)
      end

      def track_profile_view(properties = {})
        properties[:user_state] = logged_in? ? 'logged_in' : 'logged_out'
        track_usage(Events::ProfileView.new(profile_user, properties))
      end

      def tab_params
        params[:per] ||= User.profile_per_page
        params.slice(:page, :per)
      end
    end
  end
end
