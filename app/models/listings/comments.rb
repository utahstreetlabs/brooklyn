require 'anchor/models/comment'

module Listings
  module Comments
    extend ActiveSupport::Concern

    # Anchor actually supports up to 500 characters, but this lets us account for any unprintable characters that
    # might be contained in text copied from another web site and pasted into the comment box. Ultimately we'd rather
    # normalize whitespace in the input text before handing it off to Anchor.
    COMMENT_MAX_LENGTH = 480

    # Creates and returns a +Anchor::Comment+ on the listing by the specified user. Returns nil if there was an error
    # communicating with the service.
    def comment(commenter, attrs = {}, options = {})
      if attrs[:keywords].is_a?(String)
        attrs[:keywords] = ActiveSupport::JSON.decode(attrs[:keywords])
      end
      logger.debug("Commenting on listing #{self.id} as user #{commenter.id}")
      comment = Comment.create(self, commenter, attrs)
      if comment && comment.valid?
        add_tags_from_keywords(comment.keywords)
        # XXX: move after_comment callback to Comment::AfterCreated job
        notify_observers(:after_comment, commenter, comment,
          options.merge(type: :comment, keywords: comment.keywords))
      end
      comment
    end

    def add_tags_from_keywords(keywords)
      return unless keywords.present?
      hashtags = keywords.select { |k,v| v['type'] == 'tag' }
      if hashtags.any?
        newtags = Tag.find_or_create_from_hashtags(hashtags)
        add_tags(newtags)
        newtags.each { |t| track_usage(Events::ListingHashtagAdd.new(self, t)) }
      end
    end

    # Deletes a comment. Does not return a useful value.
    def delete_comment(comment_id, user)
      logger.debug("Deleting comment #{comment_id} on listing #{self.id} as user #{user.id}")
      if (comment = Comment.find(self, comment_id))
        remove_tags(comment.hashtags)
        comment.destroy
      end
    end

    # Returns the listing's most recent comments. Accepts any options supported by +Anchor::Listing.comments+.
    def recent_comments(options = {})
      logger.debug("Finding recent comments for listing #{self.id}")
      anchor_instance.comments(options)
    end

    # Returns the identified comment for the listing.
    def find_comment(id)
      logger.debug("Finding comment #{id} for listing #{self.id}")
      Anchor::Comment.find(self.id, id)
    end

    def comments_count
      anchor_instance.comments_count
    end

    # Creates and returns a +Lagunitas::CommentReply+ in response to +comment+ by the specified user. Returns nil if
    # there was an error communicating with the service.
    def reply(replier, comment, attrs = {}, options = {})
      if attrs[:keywords].is_a?(String)
        attrs[:keywords] = ActiveSupport::JSON.decode(attrs[:keywords])
      end
      logger.debug("Replying to comment #{comment.id} on listing #{self.id} as user #{replier.id}")
      reply = CommentReply.create(comment, replier, attrs)
      if reply && reply.valid?
        add_tags_from_keywords(reply.keywords)
        notify_observers(:after_comment, replier, reply,
          options.merge(type: :reply, keywords: reply.keywords))
      end
      reply
    end

    def commentable?
      self.active? || self.sold?
    end

    def comment_summary
      unless instance_variable_defined?(:@comment_summary)
        logger.debug("Fetching comment summary for listing #{self.id}")
        # XXX: Anchor::Listing.should return default data when the anchor request fails, but it doesn't seem to,
        # so until we patch that library handle it ourselves
        @comment_summary = Anchor::Listing.comment_summaries([self.id], {})[self.id] ||
          Hashie::Mash.new(total: 0, comments: {})
      end
      @comment_summary
    end

    module ClassMethods
      def comment_summaries(listing_ids, user)
        logger.debug("Fetching comment summaries for listings #{listing_ids}")
        Anchor::Listing.comment_summaries(listing_ids, user_id: user ? user.id : nil)
      end
    end
  end
end
