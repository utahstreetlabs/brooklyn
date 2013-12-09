# present a generic card collection that supports both product and tag cards
#
# i'm pretty sure this is exactly the opposite of how i'd do it if i was starting from scratch, but it allows me
# to get it done quickly and get through a ff transition with minimal pain
class CardCollection
  include Enumerable
  include Ladon::Logging

  attr_reader :user, :cards, :objects
  delegate :each, to: :cards

  def initialize(user, objects, options = {})
    # we use the available functionality of the two separate card presenters and then map the cards back to
    # our original objects to get the order right
    product_cards = ListingResults.new(user, objects.select {|o| o.is_a?(Listing)}, options).product_cards
    tag_cards = TagCards.new(user, objects.select {|o| o.is_a?(Tag)}, options).tag_cards
    # on the profile page we fix the story for all tags, so don't waste time looking it up
    if options[:default_tag_liker]
      tag_cards.each {|c| c.story = TagStory.local_stub(c.tag, :tag_liked, options[:default_tag_liker])}
    end
    @objects = objects
    @cards = objects.map do |object|
      if object.is_a?(Listing)
        product_cards.shift
      else
        tag_cards.shift
      end
    end
  end
end
