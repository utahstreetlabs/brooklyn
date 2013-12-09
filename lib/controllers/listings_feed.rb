module Controllers
  # Provides common behaviors for controllers/views that include the listings feed
  module ListingsFeed
    extend ActiveSupport::Concern

    included do
      helper_method :poll_new_stories?
    end

    module ClassMethods
      def set_listings_feed(options = {})
        before_filter(options) { load_listings_feed }
      end
    end

  protected
    def load_listings_feed
      unless defined?(@listings_feed)
        logger.debug("Loading listings feed")
        options = [:limit].each_with_object({}) do |key,map|
          map[key] = (params[key] || Brooklyn::Application.config.feed.defaults.send(key)).to_i
        end
        [:before, :after].each {|k| options[k] = params[k].to_i if params[k]}
        @listings_feed = CardFeed.new(current_user, options.merge(user_feed: network_listings_feed?))
      end
      @listings_feed
    end

    def set_listings_feed_flash
      if !@listings_feed || (@listings_feed.card_fetch_failure_type == :empty)
        set_flash_message(:notice, :feed_load_failed)
      end
    end

    def network_listings_feed?
      unless defined?(@network_listings_feed)
        @network_listings_feed = params[:feed].blank? || params[:feed] == 'network'
      end
      @network_listings_feed
    end

    def everything_listings_feed?
      not network_listings_feed?
    end

    def first_page?
      unless defined?(@first_pagge)
        @first_page = !params[:before]
      end
      @first_page
    end

    def suppress_new_story_polling
      @story_polling_suppressed = true
    end

    def poll_new_stories?
      logged_in? && !@story_polling_suppressed
    end
  end
end
