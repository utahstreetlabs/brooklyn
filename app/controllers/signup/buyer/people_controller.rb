module Signup
  module Buyer
    class PeopleController < ApplicationController
      layout 'signup/buyer'

      before_filter :load_user, only: [:follow, :unfollow]

      def index
        autofollow_list = User.autofollow_list
        interest_followees = current_user.interest_based_followees - autofollow_list
        @followees = (current_user.followees - (autofollow_list + interest_followees)).sort_by { |u| u.name.downcase }
      end

      def complete
        current_user.complete_onboarding!
        track_onboarding_people
        redirect_to session.delete(:signup_flow_destination) || root_path
      end

    protected

      def track_onboarding_people
        self.class.with_error_handling 'tracking onboarding people complete' do
          track_usage(:onboarding_people,
            network: current_user.person.connected_networks.first,
            users: current_user.followees.map(&:slug))
        end
      end

      def load_user
        @user = User.find_by_slug!(params[:person_id])
      end
    end
  end
end
