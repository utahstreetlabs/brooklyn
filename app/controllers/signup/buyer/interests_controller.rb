module Signup
  module Buyer
    class InterestsController < ApplicationController
      include Controllers::Onboarding
      include Controllers::Jsendable
      layout 'signup/buyer'

      before_filter :load_interest, only: [:like, :unlike]
      respond_to :json, only: [:index, :like, :unlike, :build_feed]

      def index
        interests = Interest.onboarding_list_by_rand(gender: (session[:gender] || current_user.gender))
        @interest_cards = InterestCards.new(interests, current_user)
        respond_to do |format|
          format.json do
            render_jsend(success: {
              modal: view_context.select_interests_modal_content(@interest_cards),
              interestsRemaining: current_user.interests_remaining_count
            })
          end
          format.html
        end
      end

      def like
        current_user.add_interest_in!(@interest, tracking: {onboarding_location: params[:l]})
        respond_to_like_unlike(@interest, true)
      end

      def unlike
        current_user.remove_interest_in(@interest)
        respond_to_like_unlike(@interest, false)
      end

      def complete
        track_interests_complete
        if feature_enabled?(:onboarding, :autofollow_collections)
          current_user.follow_autofollow_collections
        else
          follow_suggested_users(current_user)
        end
        redirect_after_interests
      end

      def build_feed
        StoryFeeds::CardFeed.build_feed(interested_user_id: current_user.id)
        track_build_feed
        #XXX: refactor feed loading logic in Feed::ListingsController
        #     so that we can pass the feed back here
        respond_with_jsend(:success)
      end

      protected

        def track_interests_complete
          self.class.with_error_handling 'tracking onboarding interests complete' do
            interests = current_user.interests.map(&:name)
            track_usage(:onboarding_interests,
              network: current_user.person.connected_networks.first,
              interests: interests, interests_count: interests.count)
          end
        end

        def track_build_feed
          self.class.with_error_handling 'tracking build feed' do
            interests = current_user.interests.map(&:name)
            track_usage('interest_modal click',
              network: current_user.person.connected_networks.first,
              interests: interests, interests_count: interests.count)
          end
        end

        def load_interest
          @interest = Interest.find(params[:interest_id])
        end

        def respond_to_like_unlike(interest, liked)
          respond_with do |format|
            format.json do
              card = InterestCard.new(interest, liked: liked)
              button = view_context.interest_card_like_button(card,
                like_path: signup_buyer_interest_like_path(card.interest),
                unlike_path: signup_buyer_interest_unlike_path(card.interest)
              )
              render_jsend(success: {button: button, liked: liked,
                                     interestsRemaining: current_user.interests_remaining_count})
            end
          end
        end

        def follow_suggested_users(user)
          user.suggested_users.each do |suggested_user|
            user.follow!(suggested_user, attrs: {suppress_followee_notifications: true, suppress_fb_follow: true},
                         follow_type: InterestFollow)
          end
        end
    end
  end
end
