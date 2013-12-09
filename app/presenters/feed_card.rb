# Base class for presenters representing feed cards.
class FeedCard
  include Ladon::Logging

  attr_accessor :story, :viewer

  def initialize(story, viewer, options = {})
    @story = story
    @viewer = viewer
  end

  def self.create(story, viewer)
    # my kingdom for scala-style pattern matching
    klass = if story.type.to_s.start_with?('listing')
      ProductCard
    elsif story.type.to_s.start_with?('tag')
      TagCard
    elsif story.type.to_s.start_with?('actor')
      ActorCard
    elsif story.type == :facebook_share_invite
      FacebookFeedDialogInviteCard
    elsif story.type == :facebook_u2u_invite
      FacebookFacepileInviteCard
    elsif story.type == :follow
      FollowCard
    elsif story.type == :promotion
      PromotionCard
    end
    klass && klass.new(story, viewer, remove_from_feed: true)
  end

  def self.eager_fetch_associations(cards, options = {})
    card_options = options.merge(listings_per_card: 9)
    card_types.each do |klass|
      typed_cards = cards.select {|c| c.is_a?(klass)}
      klass.eager_fetch_for_collection(typed_cards, options)
    end
    cards
  end

  def self.eager_fetch_for_collection(cards, options = {})
    # no-op by default
  end

  def self.card_types
    # would like to have made this a constant, but because it references subclasses, which in turn reference this
    # class as their base class, there was a circular dependency loading issue. hopefully the compiler inlines this
    # anyway.
    [ActorCard,
     FacebookFeedDialogInviteCard,
     FacebookFacepileInviteCard,
     FollowCard,
     ProductCard,
     PromotionCard,
     TagCard,
     UserCard]
  end
end
