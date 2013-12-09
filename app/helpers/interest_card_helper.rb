module InterestCardHelper
  # @param [interestCard] card card to render
  # @param [Hash] options
  # @option options [Bool] :active Whether to link listings and interests on this view
  def interest_card(card, options = {})
    card_classes = ['interest-card']
    card_classes << 'liked' if card.liked?
    content_tag(:div, :class => class_attribute(card_classes), data: {role: 'interest-card'}) do
      title = truncate(card.interest.name, length: 25)
      title = link_to(title, browse_for_sale_path(nil, card.interest.slug)) if options[:active]
      content_tag(:div, class: 'interest-products-container') do
        content_tag(:div, class: 'interest-image-container block-element') do
          interest_card_like_button(card, options)
        end
      end
    end
  end

  def interest_like_button(interest_id, liked, options = {}, &block)
    attrs = {
      id: "like-button-#{interest_id}",
      type: :button,
      data: {
        role: "like ",
        interest: interest_id,
        toggle: 'interest-like'
      }
    }
    classes = ['like-button']
    if liked
      attrs[:data][:method] = :delete
      attrs[:data][:target] = options[:unlike_path]
      classes << " selected"
    else
      attrs[:data][:method] = :put
      attrs[:data][:target] = options[:like_path]
    end
    attrs[:class] = class_attribute(classes)
    bootstrap_button(attrs, &block)
  end

  def standalone_interest_like_button(interest_id, liked, options = {})
    content_tag(:div, interest_like_button(interest_id, liked, options), class: 'interest-like-button')
  end

  def interest_card_like_button(card, options = {})
    interest_like_button(card.interest.id, card.liked?, options) do
      content_tag(:div, image_tag((card.interest.cover_photo ? card.interest.cover_photo.px_220x220.url :
                  'icons/profile_photo/px_190x190___default__.png'), height: 220, width: 220, class: "interest-image"))+
      content_tag(:div, class: 'interest-name-container') do
        content_tag(:p, card.interest.name, class: 'interest-name') +
        content_tag(:div, '', class: 'interest-state')
      end
    end
  end
end
