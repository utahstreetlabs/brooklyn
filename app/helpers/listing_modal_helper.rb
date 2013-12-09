# NOTA BENE: this stuff isn't used anywhere yet, we're simply preserving
# some old product card helpers that will be useful in the very near future
# in the new listing modal.
#
# I'd normally delete this, but this should save someone a few minutes of
# gitfoolery
module ListingModalHelper
  def listing_modal_story_arguments(story)
    case story.type
    when :listing_saved then
      default = t('listings.product_card.stories.saved.deleted_collection_name')
      {collection_name: story.collection ? story.collection.name : default}
    else
      {}
    end
  end

  def listing_modal_story_actor(card, options = {})
    return current_user if logged_in? && card.story.generated_by?(current_user)
    card.story.users.first
  end

  def listing_modal_aggregate_actor_list(card, options = {})
    out = []
    case card.story.type
    when :listing_multi_actor then
      out << aggregate_user_profile_names(card.story.users, summarize_after: 1, name_only: true, translate_current_user: true)
    when :listing_multi_actor_multi_action then
      out << aggregate_user_profile_names(card.story.users, summarize_after: 1, name_only: true, translate_current_user: true)
    else
      out << (product_card_story_actor(card) == current_user ? 'You' : card.story.actor.name)
    end
    safe_join(out)
  end

  def listing_modal_story(story)
    case story.type
    when :listing_multi_actor then
      action_list = t story.action, scope: 'listings.product_card.story'
    when :listing_multi_action then
      action_list = story.types.map { |st| t(st, scope: 'listings.product_card.multi.action') }.sort.to_sentence
      t 'text', scope: 'listings.product_card.multi.story', action_list: action_list
    when :listing_multi_actor_multi_action then
      action_list = story.types.keys.uniq.map { |st| t(st, scope: 'listings.product_card.multi.action') }.
        sort.to_sentence(two_words_connector: ' or ', last_word_connector: ', or ')
      t 'text', scope: 'listings.product_card.multi.story', action_list: action_list
    else
      t story.type, product_card_story_arguments(story).merge(scope: 'listings.product_card.story')
    end
  end

  def listing_modal_full_story(card, options = {})
    if card.story
      actor = product_card_story_actor(card)
      out = []
      out << content_tag(:div, class: 'social-story-container') do
        link_to(public_profile_path(actor)) do
          content_tag(:span, class: 'social-story', data: {role: 'social-story'}) do
            out2 = []
            if card.story.love?
              out2 << content_tag(:span, '', class: 'icons-ss-love', alt: t('listings.modal.story.loved'))
            end
            out2 << product_card_aggregate_actor_list(card)
            out2 << product_card_story(card.story)
            safe_join(out2, ' ')
          end
        end
      end
      safe_join(out)
    end
  end
end
