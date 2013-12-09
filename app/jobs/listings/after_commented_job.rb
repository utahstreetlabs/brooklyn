require 'autoshare/listing_commented'
require 'brooklyn/sprayer'
require 'facebook/open_graph_listing'
require 'ladon'

module Listings
  class AfterCommentedJob < Ladon::Job
    include Brooklyn::Sprayer

    acts_as_unique_job

    @queue = :listings

    class << self
      def work(listing_id, commenter_id, comment_id, options = {})
        with_error_handling("After comment of listing #{listing_id}", listing_id: listing_id,
                            commenter_id: commenter_id, comment_id: comment_id, options: options) do
          listing = Listing.find(listing_id)
          commenter = User.find(commenter_id)
          comment = listing.find_comment(comment_id)
          unless comment
            logger.warn("Comment #{comment_id} on listing #{listing_id} not found")
            return
          end
          clean_text = Listing.html_helper.strip_tags(comment.text)
          original = listing.find_comment(comment.parent_id) if comment.parent_id
          original_commenter = User.find(original.user_id) if original
          inject_commented_story(listing, commenter, comment, clean_text)
          if listing.seller != commenter
            inject_commented_notification_for_seller(listing, commenter, comment, clean_text)
            email_commented(listing, commenter, comment)
            autoshare_commented(listing, commenter, comment, clean_text)
          end
          if original && original_commenter && original_commenter != commenter
            email_replied(listing, original_commenter, original, commenter, comment, clean_text)
            inject_replied_notification_for_commenter(listing, original, commenter, comment, clean_text)
          end
          post_comment_to_facebook(listing, commenter, comment, clean_text)
          post_comment_notification_to_facebook(listing, commenter)
          process_mentions(listing, commenter, comment, clean_text, options)
          update_mixpanel(listing, commenter, options)
        end
      end

      def process_mentions(listing, commenter, comment, text, options)
        # note that keywords don't come from the comment because Comment currently has no way to reconstitute the
        # keywords data structure from the comment data serialized into the comment text. this means that the
        # enqueuing job is responsible for passing the keywords structure in the options hash.
        keywords = options[:keywords]
        return if keywords.blank?
        keywords.each do |key, val|
          case val[:type]
          when 'cf'
            process_mentioned_copious(listing, commenter, comment, val, text)
          when 'fb'
            process_mentioned_facebook(listing, commenter, comment, val, text)
          end
        end
      end

      def process_mentioned_copious(listing, commenter, comment, mention, text)
        mentioned = User.find_registered_users(id: mention[:id]).first
        return unless mentioned
        inject_mentioned_notification_for_mentioned(listing, commenter, comment, mentioned, text)
        email_mentioned(listing, commenter, comment, mentioned)
        track_usage(Events::ListingMentionAdd.new(listing, commenter, mentioned))
      end

      def process_mentioned_facebook(listing, commenter, comment, mention, text)
        track_usage(Events::ListingMentionAdd.new(listing, commenter, nil))
      end

      def inject_commented_notification_for_seller(listing, commenter, comment, text = comment.text)
        inject_notification(:ListingCommented, listing.seller_id, listing_id: listing.id, commenter_id: commenter.id,
                            comment_id: comment.id, comment_text: text)
      end

      def inject_replied_notification_for_commenter(listing, original, replier, reply, text = reply[:text])
        inject_notification(:ListingReplied, original.user_id, listing_id: listing.id, comment_id: original.id,
                            replier_id: replier.id, reply_id: reply[:id], reply_text: text)
      end

      def inject_mentioned_notification_for_mentioned(listing, commenter, comment, mentioned, text = comment.text)
        inject_notification(:ListingMentioned, mentioned.id, listing_id: listing.id, commenter_id: commenter.id,
                            comment_id: comment.id, comment_text: text)
      end

      def autoshare_commented(listing, commenter, comment, text = comment.text)
        listing_url = url_helpers.listing_url(listing)
        Autoshare::ListingCommented.enqueue(listing.id, listing_url, commenter.id, text)
      end

      def inject_commented_story(listing, commenter, comment, text = comment.text)
        inject_listing_story(:listing_commented, commenter.id, listing, text: text)
      end

      def post_comment_to_facebook(listing, commenter, comment, text = comment.text)
        return unless commenter.allow_autoshare?(:listing_commented, :facebook)
        listing_url = url_helpers.listing_url(listing)
        Facebook::OpenGraphListing.enqueue_at(Network::Facebook.open_graph_post_delay.from_now, listing.id,
          listing_url, commenter.id, :comment, to: listing.seller.id, message: text)
      end

      def post_comment_notification_to_facebook(listing, commenter)
        return unless feature_enabled?(:networks, :facebook, :notifications, :action, :friend_comment)
        Facebook::NotificationComment.enqueue(listing.id, commenter.id)
      end

      def email_commented(listing, commenter, comment)
        return unless listing.seller.allow_email?(:listing_comment)
        send_email(:commented, listing, commenter.id, comment.id)
      end

      def email_replied(listing, commenter, comment, replier, reply)
        return unless commenter.allow_email?(:listing_comment_reply)
        send_email(:replied, listing, commenter.id, comment.id, replier.id, reply[:id])
      end

      def email_mentioned(listing, commenter, comment, mentioned)
        return unless mentioned.allow_email?(:listing_mentioned)
        send_email(:mentioned, listing, commenter.id, comment.id, mentioned.id)
      end

      def update_mixpanel(listing, commenter, options)
        commenter.mixpanel_increment!(:comments)
        track_usage(Events::CommentListing.new(listing, type: options[:type]))
      end
    end
  end
end
