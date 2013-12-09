class ActorCards
  include Enumerable
  include Ladon::Logging

  attr_reader :user, :actor_cards
  delegate :each, to: :actor_cards

  def initialize(user, actors, options = {})
    @user = user
    @actor_cards = actors.map { |actor| ActorCard.new(nil, user, actor: actor) }
    ActorCard.eager_fetch_for_collection(@actor_cards, options)
  end
end
