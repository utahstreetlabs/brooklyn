class InterestCards
  include Enumerable
  include Ladon::Logging

  attr_reader :interest_cards, :viewer
  delegate :each, to: :interest_cards

  def initialize(interests, viewer)
    @interest_cards = interests.map{ |i| InterestCard.new(i) }
    @viewer = viewer
    eager_fetch_liked
  end

  def liked
    @interest_cards.find_all {|i| i.liked?}
  end

  def eager_fetch_liked
    if interest_cards.any?
      interest_ids = interest_cards.map {|c| c.interest.id}
      interests = viewer.interests_in(interest_ids)
      existence_idx = interests.each_with_object({}) { |interest, idx| idx[interest.id] = true }
      interest_cards.each do |card|
        card.liked = existence_idx.fetch(card.interest.id, false)
      end
    end
  end
end
