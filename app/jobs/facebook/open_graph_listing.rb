require 'ladon'

module Facebook
  class OpenGraphListing < OpenGraphJob
    @queue = :facebook
    class << self
      def work(listing_id, listing_url, actor_id, action, options = {})
        logger.debug("Posting to Facebook, listing=>#{listing_id}, action=>#{action}")
        with_error_handling("Facebook open graph listing #{action}", listing_id: listing_id) do
          listing = Listing.find(listing_id)
          actor = User.find(actor_id)
          open_graph_post(listing, listing_url, actor, action.to_sym, options)
        end
      end

      def open_graph_post(listing, listing_url, actor, action, options = {})
        profile = actor.person.for_network(:facebook)
        if profile && profile.og_postable?
          logger.debug("Posting '#{action}' for listing id #{listing.id} to Facebook open graph, profile id = #{profile.id}")
          begin
            track_action(actor, :listing, action) do
              props = options.merge(fb_ref_data: fb_ref_data(actor, listing))
              profile.post_to_ticker(open_graph_object_props(action, :listing, listing_url, props))
            end
          rescue Exception => e
            # There are any number of reasons why we might not be able to post to a user's ticker: for instance,
            # because open graph posting to a ticker isn't live for most users yet.  Facebook needs to verify our
            # objects and actions in production before they'll turn on this feature for us, which means we'll
            # be getting exceptions.  Even if it was turned on, we probably just want to log a message if we can't
            # post to a user's ticker, though in the future we might decide to invalidate a token associate with
            # an account whose password has changed.
            logger.warn("Unable to post to Facebook Open Graph uid=#{profile.uid}", e)
          end
        end
      end

      def fb_ref_data(actor, listing)
        fb_ref_user_data(actor).merge(listing_name: listing.title, seller_slug: listing.seller.slug)
      end
    end
  end
end
