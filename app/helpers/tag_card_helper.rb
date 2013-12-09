module TagCardHelper
  # @param [TagCard] card card to render
  # @param [Hash] options
  # @option options [Bool] :active Whether to link listings and tags on this view
  def tag_card(card, options = {})
    card_class = 'tag-container'
    button_class = 'button'
    if card.liked?
      card_class << ' liked'
      button_class << ' liked disabled actionable'
      button_text = 'Loved'
    else
      button_text = 'Love'
    end
    content_tag(:div, :class => card_class, data: {role: 'tag-card'}) do
      title = truncate(card.tag.name, length: 25)
      title = link_to(title, browse_for_sale_path(nil, card.tag.slug)) if options[:active]
      out = []
      out << content_tag(:div, class: 'tag-products-container') do
        content_tag(:ul, class: 'products-waffle-format waffle-format') do
          card.photos.inject(''.html_safe) do |m, photo|
            content = listing_photo_tag(photo, :small)
            content = link_to(content, listing_path(photo.listing)) if options[:active]
            m << content_tag(:li, content)
          end
        end
      end
      out << content_tag(:div, class: 'tag-info') do
        content_tag(:h3, title, class: 'tag-name')
      end
      out << content_tag(:div, class: 'tag-action-area love-button-container') do
        tag_card_like_button(card, options)
      end
      safe_join(out)
    end
  end

  def full_tag_card(card, options = {})
    options = {
      id: "tag-card-#{card.tag.id}",
      class: 'card-container no-action tag-card-v4',
      data: {
        card: 'tag'
      }
    }
    options['data-timestamp'] = card.story.created_at.to_i if card.story
    content_tag(:li, options) do
      out = []
      out << tag_story(card.story) if card.story
      out << tag_card(card, active: true, pad: 9, like_path: tag_like_path(card.tag), unlike_path:
                      tag_unlike_path(card.tag))
      safe_join(out)
    end
  end

  def tag_story(story)
    content_tag(:div, class: 'feed-container') do
      content_tag(:div, user_avatar_xsmall(story.actor, class: 'text-adjacent'), class: 'avatar-container') +
      link_to(public_profile_path(story.actor)) do
        content_tag(:div, class: 'feed-story-container') do
          content_tag(:span,class: 'feed-story') do
            ((logged_in? && story.generated_by?(current_user)) ? 'You' : story.actor.name).html_safe + ' ' +
            t(story.type, scope: 'tags.tag_card.story')
          end
        end
      end
    end
  end

  def tag_like_button(tag_id, liked, options = {})
    button_class = 'button love-button primary'
    text_class = 'icon-love'
    if liked
      button_class << ' inactive'
      button_text = options[:liked_text] || 'Loved'
      method = :DELETE
      path = options[:unlike_path]
    else
      button_text = options[:like_text] || 'Love'
      method = :PUT
      path = options[:like_path]
    end
    attrs = {id: "like-button-#{tag_id}", class: button_class, remote: true, rel: :nofollow}
    attrs.merge!(data_attrs(method: method, type: :json, action: "like", role: "love-button", link: "remote"))
    link_to(content_tag(:span, '', :class => text_class) + content_tag(:span, button_text, :class => 'text'), path,
      attrs)
  end

  def standalone_tag_like_button(tag_id, liked, options = {})
    content_tag(:div, tag_like_button(tag_id, liked, options), class: 'tag-like-button')
  end

  def tag_card_like_button(card, options = {})
    tag_like_button(card.tag.id, card.liked?, options)
  end
end
