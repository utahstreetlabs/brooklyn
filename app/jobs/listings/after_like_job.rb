require 'brooklyn/sprayer'
require 'ladon'

module Listings
  class AfterLikeJob < Ladon::Job
    include Brooklyn::Sprayer
    include Stats::TutorialTracking

    @queue = :listings

    class << self
      def work(listing_id, liker_id, like_id, options = {})
        with_error_handling("After like of listing #{listing_id}") do
          listing = Listing.find(listing_id)
          liker = User.find(liker_id)
          like = Pyramid::User::Likes.get(liker_id, :listing, listing_id)
          # note that updating mixpanel for every like counts re-likes, but this is what we were doing before when
          # we updated mixpanel at the controller level
          update_mixpanel
          # In the event of an error, we get back nil from pyramid; we're going to just
          # be silent and not inject notifications, etc. in this case.
          return unless like.present?
          unless like.tombstone
            inject_like_story(listing, liker)
            post_like_to_facebook(listing, liker)
            post_like_notification_to_facebook(listing, liker)
          end
          unless (liker == listing.seller) || like.tombstone
            email_liked(listing, liker)
            autoshare_liked(listing, liker, options)
            notify_seller_liked(listing, liker)
          end
          track_tutorial_progress(:like) if liker.likes_count == 1
        end
      end

      def autoshare_liked(listing, liker, options = {})
        listing_url = url_helpers.listing_url(listing)
        Autoshare::ListingLiked.enqueue(listing.id, listing_url, liker.id, options)
      end

      def inject_like_story(listing, liker)
        inject_listing_story(:listing_liked, liker.id, listing)
      end

      def notify_seller_liked(listing, liker)
        inject_notification(:ListingLike, listing.seller_id, listing_id: listing.id, liker_id: liker.id)
      end

      def email_liked(listing, liker)
        return unless listing.seller.allow_email?(:listing_like)
        send_email(:liked, listing, liker.id)
      end

      def post_like_to_facebook(listing, liker)
        return unless liker.allow_autoshare?(:listing_liked, :facebook)
        listing_url = url_helpers.listing_url(listing)
        Facebook::OpenGraphListing.enqueue_at(Network::Facebook.open_graph_post_delay.from_now, listing.id,
          listing_url, liker.id, :love)
      end

      def post_like_notification_to_facebook(listing, liker)
        return unless feature_enabled?(:networks, :facebook, :notifications, :action, :friend_like)
        Facebook::NotificationLike.enqueue(listing.id, liker.id)
      end

      def update_mixpanel
        track_usage(:like_listing)
      end
    end
  end
end
