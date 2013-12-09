class PromotionStory < LocalStory
  attr_reader :created_at, :name

  # name should be a descriptive symbol. it is used to find copy, images and
  # links for the promo card
  def initialize(name, options = {})
    @name = name
    super(options)
  end

  def type
    :promotion
  end
end
