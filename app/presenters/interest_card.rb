class InterestCard
  include Ladon::Logging

  attr_accessor :interest, :liked

  def initialize(interest, options = {})
    @interest = interest
    @liked = options.fetch(:liked, false)
  end

  def liked?
    !!liked
  end
end
