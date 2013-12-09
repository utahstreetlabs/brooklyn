module UserCardHelper
  def user_card(card, options = {})
    container_classes = %w(user-card card-container)
    container_classes << 'logged_in' if card.viewer
    container_classes += Array.wrap(options[:classes]) if options[:classes].present?
    container_options = {
      id: options.fetch(:id, "user-card-#{card.user.id}"),
      class: class_attribute(container_classes),
      data: {
        card: options.fetch(:card, 'user'),
        user: card.user.id,
        source: options.fetch(:source, 'user-card')
      }
    }
    container_options[:timestamp] = options[:timestamp] if options[:timestamp].present?
    content_tag(:li, container_options) do
      out = []
      out << user_card_listing_thumbnails(card)
      out << user_card_profile_info(card)
      out << user_card_stats(card)
      out << tag(:hr)
      out << user_card_shared_interest(card)
      out << user_card_follow_button(card)
      safe_join(out)
    end
  end

  def user_card_follow_button(card)
    content_tag(:div, class: 'product-action-area') do
      follow_control(card.user, card.viewer, class: 'btn-overlay btn-small', following: card.following)
    end
  end

  def user_card_profile_photo(card)
    content_tag(:div, class: 'actor-profile') do
      user_card_link_to_user_profile(card) do
        image_tag(user_profile_photo_url(card.user, 150, 150), size: '150x150', alt: card.user.name)
      end
    end
  end

  def user_card_listing_thumbnails(card)
    content_tag(:div, class: 'product-image-container') do
      out = []
      out << content_tag(:ul, class: 'waffle-format thumbnails') do
        out2 = card.slots.map do |slot|
          content_tag(:li, id: "user-card-listing-slot-#{slot.position}") do
            unless slot.blank?
              link_to(listing_photo_tag(slot.photo, :small, size: '75x75', alt: slot.listing.title),
                      listing_path(slot.listing),
                      data: {toggle: 'listing-modal', listing: slot.listing.id, url: listing_modal_path(slot.listing)})
            end
          end
        end
        out2 << user_card_profile_photo(card)
        safe_join(out2)
      end
      safe_join(out)
    end
  end

  def user_card_profile_info(card)
    user_card_link_to_user_profile(card) do
      content_tag(:div, class: 'product-info') do
        content_tag(:span, card.user.name, class: 'product-title ellipsis')
      end
    end
  end

  def user_card_stats(card)
    user_card_link_to_user_profile(card) do
      content_tag(:div, class: "social-story-container") do
        content_tag(:span, class: "social-story") do
          out = []
          out << t('user_card.stats.listings', count: card.listing_count) if card.listing_count > 0
          out << t('user_card.stats.collections', count: card.collection_count) if card.collection_count > 0
          out << t('user_card.stats.likes', count: card.like_count) if card.like_count > 0
          bar_separated(*out)
        end
      end
    end
  end

  def user_card_shared_interest(card)
    content_tag(:div, class: 'price-box') do
      out = []
      out << user_card_link_to_user_profile(card) do
        content_tag(:div, class: 'actor-activities') do
          if card.viewer == card.user
            t('user_card.shared_interest.self')
          else
            interest = card.shared_interest ? card.shared_interest.name : t('user_card.shared_interest.default')
            t('user_card.shared_interest.description', interest: interest)
          end
        end
      end
      safe_join(out)
    end
  end

  def user_card_link_to_user_profile(card, &block)
    link_to(public_profile_path(card.user), &block)
  end
end
