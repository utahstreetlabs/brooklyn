class PromotionCard < FeedCard
  def config
    Brooklyn::Application.config.feed.card.promotion.send(story.name)
  end

  def link
    config.link.respond_to?(:call) ? config.link.call : config.link
  end

  def self.active_promos
    Brooklyn::Application.config.feed.card.promotion.active.find_all { |c| feature_enabled?(:feed, :promotion_card, c) }
  end
end
