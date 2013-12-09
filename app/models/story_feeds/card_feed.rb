# Models stories that reside in Rising Tide.
module StoryFeeds
  class CardFeedFetchFailed < Exception;
    attr_reader :fallback_feed, :fallback_type
    def initialize(fallback_feed, fallback_type)
      @fallback_feed = fallback_feed
      @fallback_type = fallback_type
    end

    def ==(other)
      self.fallback_feed == other.fallback_feed &&
        self.fallback_type == other.fallback_type
    end
  end

  class CardFeed < StoryFeeds::Feed
    include Stats::Trackable
    decorates RisingTide::CardFeed

    def self.wrap_stories(stories)
      stories.map {|s| Story.new_from_rising_tide(s)}
    end

    # Returns an ordered list of stories from a feed within the limits provided, both in terms of time and counts.
    #
    # @param [Hash] options
    # @option options [Integer] :interested_user_id the id of the user whose feed we should return
    # @option options [Integer] :offset the number of stories to skip
    # @option options [Integer] :limit the maximum number of documents to return
    # @option options [Time] :before only stories created before this time are considered
    # @option options [Time] :after only stories created after this time are considered
    # @return [Kaminari::PaginatableArray] of +RisingTide::Story+ objects
    def self.fetch_slice(options = {})
      decorated_class.find_slice(options)
    rescue Exception => e
      logger.error("Failed to get feed for #{options}: #{e.inspect} #{e.message}")
      raise CardFeedFetchFailed.new([], :empty)
    end

    def self.build_feed(options = {})
      user_id = options[:interested_user_id]
      track_benchmark(:on_demand_feed_build, user_id: user_id, source: options[:source]) do
        decorated_class.build(user_id)
      end
    rescue Exception => e
      unless options[:ignore_failure]
        track_usage(:on_demand_feed_build_failed, user_id: user_id)
        logger.error("Could not build feed for user #{user_id}: #{e.inspect} #{e.message}, serving curated feed")
        raise CardFeedFetchFailed.new(wrap_stories(decorated_class.find_slice(options.reject {|(k, v)| k == :interested_user_id })), :curated)
      end
    end

    # Returns the most recent listing stories in reverse chronological order. Only completely populated stories
    # are returned; this may result in fewer than the requested number of stories being returned.
    #
    # @param [Hash] options
    # @see +#fetch_slice+
    # @see RisingTide::Story#find_most_recent
    # @see #resolve_associations
    # @return [Array] a list of completely populated +Story+ objects
    def self.find_slice(options = {})
      feed = fetch_slice(options)
      feed = build_feed(options) if feed.empty? && user_feed?(options) && first_page?(options)
      wrap_stories(feed)
    end

    protected

      def self.first_page?(options)
        !options[:before]
      end

      def self.user_feed?(options)
        options[:interested_user_id]
      end
  end
end
