class CardFeed
  include Enumerable
  include Ladon::Logging

  attr_reader :viewer, :cards, :card_fetch_failure_type
  delegate :each, to: :cards

  def initialize(viewer, options = {})
    @viewer = viewer
    options[:interested_user_id] = viewer.id if options.delete(:user_feed)
    @cards = load_cards(options)
  end

  def load_cards(options)
    cards = load_stories(options).map { |story| FeedCard.create(story, viewer) }
    FeedCard.eager_fetch_associations(cards, options)
  end

  def load_stories(options)
    stories = feed_stories(options)

    if user_feed?(options) && first_page?(options)
      # for each of the singular card types, if a story exists, add it in the appropriate position
      [:invite, :follow, :promotion].
        # sort by position so that inserting into stories puts the card in the expected place (inserting at position
        # 8 then at position 1 would move the first story into position 9).
        map { |t| [t, self.class.card_position(t)] }.
        sort { |a, b| a[1] <=> b[1] }.
        each do |(type, position)|
          story = card_story(type, options)
          if story
            if stories.size >= position
              stories.insert(position-1, story)
            else
              stories << story
            end
          end
        end
    end

    stories.group_by(&:class).each do |klass, typed_stories|
      klass.resolve_associations(typed_stories) if klass.respond_to?(:resolve_associations)
    end

    stories.select(&:complete?)
  end

  # @see StoryFeeds::CardFeed#find_slice
  def feed_stories(options)
    StoryFeeds::CardFeed.find_slice(options)
  rescue StoryFeeds::CardFeedFetchFailed => e
    @card_fetch_failure_type = e.fallback_type
    e.fallback_feed
  end

  def card_story(card_type, options)
    case card_type.to_sym
    when :invite then invite_story(options)
    when :follow then follow_story(options)
    when :promotion then promotion_story(options)
    else raise ArgumentError.new("Unknown card type #{card_type}")
    end
  end

  def invite_story(options = {})
    if feature_enabled?(:feed, :invite_card, :fb_u2u_request) && can_show_fb_u2u_invite_card?
      friend_profiles = viewer.invite_suggestions(self.class.facebook_facepile_invite_card_count)
      FacebookU2uInviteStory.new(friend_profiles)
    elsif feature_enabled?(:feed, :invite_card, :fb_feed_dialog)
      FacebookShareInviteStory.new
    end
  end

  # Returns a truthy value if the viewer is connected to Facebook.
  def can_show_fb_u2u_invite_card?
    viewer.for_network(Network::Facebook.symbol)
  end

  def follow_story(options = {})
    if feature_enabled?(:feed, :follow_card, :fb)
      followee = viewer.follow_suggestions(1, random: true).first
      if followee
        FollowStory.new(follower: viewer, followee: followee)
      end
    end
  end

  def promotion_story(options = {})
    active_promos = PromotionCard.active_promos
    PromotionStory.new(active_promos.sample) unless active_promos.empty?
  end

  def start_time
    unless defined?(@start_time)
      @start_time = @cards.last && @cards.last.story.created_at.to_i
    end
  end

  def end_time
    unless defined?(@end_time)
      @end_time = (@cards.first && @cards.first.story.created_at.to_i)
    end
  end

  def user_feed?(options = {})
    !!options[:interested_user_id]
  end

  def first_page?(options = {})
    !options[:before]
  end

  def self.facebook_facepile_invite_card_count
    config.card.facebook_facepile_invite.count
  end

  def self.card_position(card_type)
    config.card.send(card_type.to_sym).position
  end

  def self.story_types
    config.card.story_types
  end

  def self.config
    Brooklyn::Application.config.feed
  end

  def self.count_most_recent(last_update, options)
    Story.count_most_recent(last_update, options.merge(types: self.story_types))
  end
end
