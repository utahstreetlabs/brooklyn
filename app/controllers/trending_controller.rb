class TrendingController < ApplicationController
  include Controllers::InfinitelyScrollable

  def show
    @welcome_header = :trending
    days = Brooklyn::Application.config.home.trending.window
    per_page = Brooklyn::Application.config.home.trending.per_page
    params[:per] = per_page
    params[:date] ||= Time.zone.now.to_i
    @page_manager = popular_listing_ids = Listing.recently_liked(days, params)
    popular_listings = Listing.visible(popular_listing_ids)
    if popular_listing_ids.any?
      popular_listings = popular_listings.order_by_ids(popular_listing_ids)
    else
      logger.warn("Trending page found 0 listings")
      popular_listings = popular_listings.reverse_order.limit(per_page)
    end
    @popular_feed = CardCollection.new(current_user, popular_listings)
    respond_to do |format|
      format.html
      format.json do
        results = { cards: view_context.feed_cards(@popular_feed) }
        results[:more] = next_page_path unless last_page?
        render_jsend(success: results)
      end
    end
  end
end
