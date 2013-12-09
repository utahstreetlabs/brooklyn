require 'ladon'

module Facebook
  class OpenGraphTag < OpenGraphJob
    @queue = :facebook
    class << self
      def work(tag_id, tag_url, actor_id, action, options = {})
        logger.debug("Posting to Facebook, tag=>#{tag_id}, action=>#{action}")
        with_error_handling("Facebook open graph tag #{action}", tag_id: tag_id) do
          tag = Tag.find(tag_id)
          actor = User.find(actor_id)
          open_graph_post(tag, tag_url, actor, action.to_sym, options)
        end
      end

      def open_graph_post(tag, tag_url, actor, action, options = {})
        profile = actor.person.for_network(:facebook)
        if profile && profile.og_postable?
          logger.debug("Posting '#{action}' for tag id #{tag.id} to Facebook open graph, profile id = #{profile.id}")
          begin
            track_action(actor, :tag, action) do
              props = options.merge(fb_ref_data: fb_ref_data(actor, tag))
              profile.post_to_ticker(open_graph_object_props(action, :tag, tag_url, props))
            end
          rescue Exception => e
            logger.warn("Unable to post to Facebook Open Graph uid=#{profile.uid}", e)
          end
        end
      end

      def fb_ref_data(actor, tag)
        fb_ref_user_data(actor).merge(tag_slug: tag.slug)
      end
    end
  end
end
