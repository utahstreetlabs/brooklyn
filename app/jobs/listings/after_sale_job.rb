require 'brooklyn/sprayer'
require 'facebook/open_graph_listing'
require 'ladon'
require 'likes/reveal_likeable_likes_job'

module Listings
  class AfterSaleJob < Ladon::Job
    include Brooklyn::Sprayer

    @queue = :listings

    class << self
      def work(id)
        with_error_handling("After sale of listing #{id}") do
          listing = Listing.find(id)
          inject_sale_story(listing)
          post_sale_to_facebook(listing)
          reveal_likes(listing)
          track_listing_sale(listing)
        end
      end

      def inject_sale_story(listing)
        inject_listing_story(:listing_sold, listing.seller_id, listing, buyer_id: listing.buyer_id)
      end

      def post_sale_to_facebook(listing)
        if listing.seller.allow_autoshare?(:listing_sold, :facebook)
          options = {}
          options[:user_generated_images] = Network::Facebook.user_generated_images(listing, fb_image_count)

          listing_url = url_helpers.listing_url(listing)
          Facebook::OpenGraphListing.enqueue_at(Network::Facebook.open_graph_post_delay.from_now, listing.id,
            listing_url, listing.seller.id, :sell, options)
        end
      end

      def reveal_likes(listing)
        Likes::RevealLikeableLikesJob.enqueue(:listing, listing.id)
      end

      def track_listing_sale(listing)
        track_usage(:complete_order, user: listing.order.buyer)
        track_usage(:sell_listing, user: listing.seller)
      end

      def fb_image_count
        Brooklyn::Application.config.networks.facebook.og.sell.image_count
      end
    end
  end
end
