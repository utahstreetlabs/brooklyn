class TagCards
  include Enumerable
  include Ladon::Logging

  attr_reader :user, :tag_cards
  delegate :each, to: :tag_cards

  def initialize(user, tags, options = {})
    @user = user
    @tag_cards = tags.map { |tag| TagCard.new(nil, user, tag: tag) }
    TagCard.eager_fetch_for_collection(@tag_cards, options)
  end

  # Returns the cards for tags which the viewing user likes.
  def liked
    @tag_cards.find_all {|c| c.liked?}
  end
end
