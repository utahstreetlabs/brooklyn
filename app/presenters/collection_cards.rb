class CollectionCards
  include Enumerable
  include Ladon::Logging

  attr_reader :viewer, :cards
  delegate :each, to: :cards

  def initialize(viewer, collections, options = {})
    @viewer = viewer
    @cards = collections.map { |collection| CollectionCard.new(collection, viewer) }
    CollectionCard.eager_fetch_associations(cards, options)
    @cards = @cards.find_all { |card| card.complete? }
  end
end
