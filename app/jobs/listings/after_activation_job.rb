require 'autoshare/listing_activated'
require 'brooklyn/sprayer'
require 'email_listing_activated'
require 'facebook/open_graph_listing'
require 'ladon'
require 'likes/reveal_likeable_likes_job'

module Listings
  class AfterActivationJob < Ladon::Job
    include Brooklyn::Sprayer

    @queue = :listings

    class << self

      # @options options [Boolean] :first_activation (false) whether or not this is the first time this listing has been activated
      def work(id, options = {})
        with_error_handling("After activation of listing #{id}") do
          listing = Listing.find(id)
          email_activated(listing)
          email_seller_welcome(listing)
          autoshare_activated(listing)
          facebook_activated(listing)
          reveal_likes(listing)
          update_mixpanel(listing, options)
        end
      end

      def email_activated(listing)
        EmailListingActivated.enqueue(listing.id)
      end

      def email_seller_welcome(listing)
        if listing.seller.seller_listings.size == 1
          send_email(:seller_welcome, listing)
        end
      end

      def autoshare_activated(listing)
        Autoshare::ListingActivated.enqueue(listing.id, url_helpers.listing_url(listing))
      end

      def facebook_activated(listing)
        if listing.seller.allow_autoshare?(:listing_activated, :facebook)
          options = {
            user_generated_images: Network::Facebook.user_generated_images(listing, fb_image_count)
          }
          Facebook::OpenGraphListing.enqueue_at(Network::Facebook.open_graph_post_delay.from_now, listing.id,
                                                url_helpers.listing_url(listing), listing.seller.id, :post, options)
        end
      end

      def reveal_likes(listing)
        Likes::RevealLikeableLikesJob.enqueue(:listing, listing.id)
      end

      # @options options [Boolean] :first_activation (false) whether or not this is the first time this listing has been activated
      def update_mixpanel(listing, options = {})
        listing.seller.mark_lister!
        listing.seller.mixpanel_sync!
        if options[:first_activation]
          if listing.is_a?(ExternalListing)
            track_usage(Events::PublishExternalListing.new(listing))
          else
            track_usage(Events::PublishListing.new(listing))
          end
          listing.seller.mixpanel_increment!(:listings_created)
        end
      end

      def fb_image_count
        Brooklyn::Application.config.networks.facebook.og.post.image_count
      end

      def fb_image_version
        Brooklyn::Application.config.networks.facebook.og.post.image_version
      end
    end
  end
end
