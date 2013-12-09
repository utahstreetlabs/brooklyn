require 'brooklyn/sprayer'
require 'ladon'

module Tags
  class AfterLikeJob < Ladon::Job
    include Brooklyn::Sprayer

    @queue = :tags

    class << self
      def work(tag_id, liker_id, options = {})
        with_error_handling("After like of tag #{tag_id}") do
          tag = Tag.find(tag_id)
          liker = User.find(liker_id)
          like = Pyramid::User::Likes.get(liker_id, :tag, tag_id)
          # In the event of an error, we get back nil from pyramid; we're going to just
          # be silent and not inject notifications, etc. in this case.
          return unless like.present?
          unless like.tombstone
            inject_like_story(tag, liker) unless options[:skip_story]
            post_like_to_facebook(tag, liker)
          end
        end
      end

      def inject_like_story(tag, liker)
        inject_story(:tag_liked, liker.id, tag_id: tag.id)
      end

      def post_like_to_facebook(tag, liker)
        # Note that we use "listing_liked" here -- that's because we save our
        # timeline loves autoshare preference as "listing_liked"
        return unless liker.allow_autoshare?(:listing_liked, :facebook)
        tag_url = url_helpers.browse_for_sale_url(path_tags: tag.slug)
        Facebook::OpenGraphTag.enqueue_at(Network::Facebook.open_graph_post_delay.from_now, tag.id, tag_url, liker.id,
          :love)
      end
    end
  end
end
