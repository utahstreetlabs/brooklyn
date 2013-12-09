module Signup
  module Buyer
    class FeedBuildsController < ApplicationController
      include Controllers::Jsendable

      respond_to :json, only: [:create]

      def create
        StoryFeeds::CardFeed.build_feed(interested_user_id: current_user.id)
        track_build_feed
        #XXX: refactor feed loading logic in Feed::ListingsController
        #     so that we can pass the feed back here
        respond_with_jsend(:success)
      end

      protected
        def track_build_feed
          self.class.with_error_handling 'tracking build feed' do
            interests = current_user.interests.map(&:name)
            track_usage('interest_modal click',
              network: current_user.person.connected_networks.first,
              interests: interests, interests_count: interests.count)
          end
        end
    end
  end
end
