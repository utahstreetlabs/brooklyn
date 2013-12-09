module Signup
  module Buyer
    class FriendsController < ApplicationController
      layout 'signup/buyer'
      respond_to :json, only: [:follow_suggestions]

      def index
      end

      def follow_suggestions
        invite_suggestions = current_user.person.invite_suggestions(Brooklyn::Application.config.onboarding_follow.max_suggestions)
        profile = current_user.for_network(:facebook)
        follow_suggestions = Hash[*User.network_followers(profile, registered_only: true).flatten] if profile
        exhibit = Signup::Buyer::FollowSuggestionsExhibit.new(follow_suggestions, invite_suggestions, current_user, view_context)
        unless profile.synced? && profile.ranked?
          logger.debug("Returning follow suggestions with profile synced: #{profile.synced?} and friends ranked: #{profile.ranked?}.")
        end
        render_jsend(success: {suggestions: exhibit.render})
      end

      def complete
        follow(params[:followee_ids])
        # if the follow friends modal is on, onboarding was
        # "completed" after the interests step
        current_user.complete_onboarding! unless feature_enabled?('onboarding.follow_friends_modal')
        track_onboarding_people
        respond_to do |format|
          format.json { render_jsend(:success) }
          format.all { redirect_to session.delete(:signup_flow_destination) || root_path }
        end
      end

    protected

      def follow(followee_ids)
        current_user.follow_all!(User.find(followee_ids.split(','))) if followee_ids
      end

      def track_onboarding_people
        self.class.with_error_handling 'tracking onboarding people complete' do
          track_usage(:onboarding_friends,
            network: current_user.person.connected_networks.first,
            users: current_user.followees.map(&:slug))
        end
      end
    end
  end
end
