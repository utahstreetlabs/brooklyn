require 'ladon'

module Facebook
  class OpenGraphUser < OpenGraphJob
    @queue = :facebook
    class << self
      def work(user_id, profile_url, action)
        Rails.logger.debug("Posting to Facebook, user=>#{user_id}, action=>#{action}")
        with_error_handling("facebook open graph user #{action}", user_id: user_id) do
          user = User.find(user_id)
          open_graph_post(user, profile_url, action.to_sym)
        end
      end

      # Post that an action, such as a follow, that user took on the target_url for the object
      def open_graph_post(user, target_url, action)
        profile = user.person.for_network(:facebook)
        if profile && profile.og_postable?
          logger.debug("Posting #{action} for user id #{user.id} to Facebook open graph, profile id = #{profile.id}")
          begin
            track_action(user, :user, action) do
              profile.post_to_ticker(open_graph_object_props(action, :user, target_url))
            end
          rescue Exception => e
            logger.warn("Unable to post to Facebook Open Graph uid=#{profile.uid}", e)
          end
        end
      end
    end
  end
end
