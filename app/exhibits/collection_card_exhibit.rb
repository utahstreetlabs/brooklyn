class CollectionCardExhibit < Exhibitionist::Exhibit
  include Exhibitionist::RenderedWithHelper
  set_helper :collection_card
  attr_reader :card

  def initialize(collection, viewer, context)
    super(collection, viewer, context)
    @card = CollectionCard.new(collection, viewer)
    CollectionCard.eager_fetch_associations(Array.wrap(@card))
  end

  def args
    [card]
  end
end

