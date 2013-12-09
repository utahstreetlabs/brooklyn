class CollectionCardsExhibit < Exhibitionist::Exhibit
  include Exhibitionist::RenderedWithHelper
  set_helper :collection_cards
  attr_reader :cards, :profile_user

  def initialize(profile_user, viewer, context)
    super(profile_user, viewer, context)
    @profile_user = profile_user
    @cards = CollectionCards.new(viewer, profile_user.collections.sort { |a, b| b.created_at <=> a.created_at })
  end

  def args
    [cards, profile_user]
  end
end

