module PromotionCardHelper
  def promotion_card(card, options = {})
    name = card.story.name
    data = {}
    data[:user] = current_user.slug if logged_in?
    data[:promotion] = name
    content_tag(:li, class: 'card-container card-container-v4 logged-in liked promotion-card',
                     data: data.merge(role: 'promotion-card')) do
      out = []
      out << content_tag(:div, class: 'feed-container') do
        out2 = []
        out2 << content_tag(:div, class: 'avatar-container') do
          link_to '', card.link, class: 'avatar text-adjacent from-copious promotion-link'
        end
        out2 << content_tag(:div, class: 'feed-story-container') do
          link_to card.link, class: 'promotion-link' do
            content_tag(:div, t("promotion_card.#{name}.story"), class: 'feed-story')
          end
        end
        safe_join(out2)
      end
      out << content_tag(:div, '', class: 'product-image-container') do
        image_tag card.config.image, width: '232', height: '302'
      end
      out << content_tag(:div, class: 'product-action-area') do
        content_tag(:div, class: 'primary-button-container') do
          link_to card.link, class: 'promotion-link' do
            content_tag(:span, t("promotion_card.#{name}.action"), class: 'promotion-button btn primary full-width')
          end
        end
      end
      safe_join(out)
    end
  end
end
