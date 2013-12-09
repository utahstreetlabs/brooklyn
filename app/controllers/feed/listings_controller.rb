class Feed::ListingsController < ApplicationController
  include Controllers::ListingsFeed

  respond_to :json
  set_listings_feed only: :index

  # Returns a set of listing stories from a user's feed.
  # @param [Hash] params parameters passed to risingtide to fetch recent stories
  # @options params [Integer] :per number of items to list per page
  # @options params [Integer] :page which page of items to fetch (offset)
  def index
    end_time = @listings_feed.end_time.to_i
    results = {stories: view_context.feed_cards(@listings_feed, source: :feed), start_time: @listings_feed.start_time.to_i,
      end_time: end_time, new_count: 0}
    render_jsend(success: results)
  end

  def destroy
    # look the listing up so we 404 if it doesn't exist
    listing = Listing.find(params[:id].to_i)
    Dislike.create(user: current_user, listing: listing)
    track_usage(:remove_listing, username: current_user.slug, listing_name: listing.slug)
    render_jsend :success
  end

  def count
    render_jsend success: {count: 0}
  end

  def refresh_timestamp
    if (ts = params[:timestamp].to_i) > 0
      current_user.set_last_feed_refresh_time(Time.zone.at(ts))
    end
    render_jsend :success
  end
end
