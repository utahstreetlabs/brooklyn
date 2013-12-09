module ActorCardHelper
  # @param [ActorCard] card card to render
  # @param [Hash] options
  # @option options [Bool] :active Whether to link listings and actors on this view
  def actor_card_photos(card, options = {})
    out = []
    title = truncate(actor_name(card.story), length: 35)
    title = link_to(title, public_profile_path(card.actor)) if options[:active]
    # Digest card images
    out << content_tag(:div, class: 'product-image-container') do
      content_tag(:ul, class: 'waffle-format thumbnails') do
        digests = []
        digests << card.photos.sort_by(&:created_at).reverse.slice(0..15).inject(''.html_safe) do |m, photo|
          content = listing_photo_tag(photo, :small)
          content = link_to(content, listing_path(photo.listing)) if options[:active]
          m << content_tag(:li, content)
        end
        digests << content_tag(:div, user_avatar_large(card.actor), class: 'actor-profile')
        safe_join(digests)
      end
    end
    safe_join(out)
  end

  def actor_card_content(card, options = {})
    out = []
    out << link_to(public_profile_path(card.actor)) do
      out1 = []
      out1 << actor_card_name(card, options)
      out1 << actor_stats(card, options)
      out1 << actor_story(card, options)
      out1 << actor_actions(card, options) if logged_in? && current_user != card.actor
      safe_join(out1)
    end
    safe_join(out)
  end

  def actor_card_name(card, options = {})
    name = truncate(actor_name(card.story), length: 35)
    content_tag(:div, class: 'product-info') do
      content_tag(:span, name, class: 'product-title ellipsis')
    end
  end

  def actor_story(card, options = {})
    content_tag(:div, class: 'price-box') do
      out = []
      out << link_to(public_profile_path(card.actor)) do
        content_tag(:div, class: 'actor-activities') do
          out2 = []
          out2 << tag(:hr)
          out2 << content_tag(:span, card.story.count, class: 'actor-activities') + ' Recent Activities'
          safe_join(out2)
        end
      end
      safe_join(out)
    end
  end

  def actor_actions(card, options = {})
    content_tag(:div, class: 'product-action-area') do
      follow_control(card.actor, current_user, class: 'btn-overlay btn-small')
    end
  end

  def actor_card(card, options = {})
    options = {
      id: "actor-card-#{card.actor.id}",
      class: 'card-container no-action digest-card',
      data: {
        card: 'actor'
      }
    }
    options['data-timestamp'] = card.story.created_at.to_i if card.story
    content_tag(:li, options) do
      out = []
      out << actor_card_photos(card, active: true, pad: 16)
      out << actor_card_content(card, options)
      safe_join(out)
    end
  end

  def actor_stats(card, options = {})
    content_tag(:div, class: 'social-story-container') do
      link_to(public_profile_path(card.story.actor)) do
        content_tag(:span, class: 'social-story') do
          spacer = '&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;'
          out = ''
          out << t('listings.product_card.stats.listings', count: card.visible_listings_count)
          out << spacer + t('listings.product_card.stats.loves', count: card.likes_count)
          out << spacer + t('listings.product_card.stats.collections', count: card.collections_count)
          out.html_safe
        end
      end
    end
  end

  def actor_name(story)
    (logged_in? && story.generated_by?(current_user)) ? 'You' : story.actor.name
  end
end
