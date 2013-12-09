module FollowCardHelper
  def follow_card(card, options = {})
    mp_view_event('follow_card', source: 'feed', follower: card.follower.slug, followee: card.followee.slug)
    card_options = {
      classes: %w(follower-card-container),
      id: "follow-card-#{card.user.id}",
      card: 'follow',
      source: 'follow-card'
    }
    card_options[:timestamp] = card.story.created_at.to_i if card.story
    user_card(card, card_options)
  end
end
