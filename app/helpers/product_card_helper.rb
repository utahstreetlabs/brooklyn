module ProductCardHelper
  def product_card_recommend_button(card, options = {})
    out = []
    recommend_modal_id = "recommend-modal-#{card.listing.id}"
    out << recommend_button(data: {target: "##{recommend_modal_id}-modal"}, on_hover_button: true)
    out << recommend_modal(current_user, card.listing, id: recommend_modal_id, photo: card.photo)
    safe_join(out)
  end

  def product_card_removed_from_collection_message
    content_tag(:span, t('product_card.v4.collection.removed'), data: {role: 'removed-from-collection'},
                class: 'removed')
  end

  def product_card_v5(card, options = {})
    li_classes = %w(card-container)
    li_classes << 'logged_in' if logged_in?
    li_classes << ' liked' if card.liked
    li_options = {
      id: "product-card-#{card.listing.id}",
      class: class_attribute(li_classes),
      data: {
        card: 'product',
        listing: card.listing.id,
        source: options.fetch(:source, 'listing-card')
      }
    }

    li_options[:data][:timestamp] = card.story.created_at.to_i if card.story
    content_tag(:li, li_options) do
      out = []
      out << product_card_link_to_listing(card.listing, params: {src: options[:refer_source]}) do
        out2 = []
        if card.photo
          out2 << product_card_v5_photo(card, options)
        end
        out2 << product_card_v5_info(card, options)
        out2 << product_card_story(card, options)
        out2 << product_card_v5_price(card, options)
        out2 << product_card_v5_actions(card, options) if logged_in?
        out2 << product_card_v5_remove(card, options) if card.remove_from_feed && feature_enabled?(:feed, :removal)
        out2 << product_card_v5_admin_feature(card, options) if card.viewer && card.viewer.admin?
        safe_join(out2)
      end
      safe_join(out)
    end
  end
  alias :product_card :product_card_v5

  def product_card_link_to_listing(listing, options = {}, &block)
    options = options.dup
    params = options.delete(:params) || {}
    if feature_enabled?('feed.product_card.listing_modal')
      options[:data] ||= {}
      options[:data][:toggle] = 'listing-modal'
      options[:data][:listing] = listing.id
      options[:data][:url] = listing_modal_path(listing)
    end
    link_to(listing_path(listing, params), options, &block)
  end

  def product_card_v5_photo(card, options = {})
    content_tag(:div, class: 'product-image-container') do
      out = []
      out << listing_photo_tag(card.photo, :medium, class: 'product-image', data: {role: 'product-image'})
      if card.listing.sold?
        out << content_tag(:span, nil, class: 'icons-label-sold')
      elsif card.listing.new?
        out << content_tag(:span, nil, class: 'icons-label-new')
      end
      safe_join(out)
    end
  end

  def product_card_v5_admin_feature(card, options = {})
    content_tag(:div, class: 'product-action-area admin-area') do
      out = []
      out << product_card_feature_button(card.listing, card.featured)
      safe_join(out)
    end
  end

  def product_card_v5_actions(card, options = {})
    base_class = 'product-action-area'
    content_tag(:div, class: base_class, data: {listing: card.listing.id, source: 'listing-card'}) do
      out = []
      out << listing_love_button(card.listing, card.liked)
      out << product_card_save_button(card.listing, current_user.collections, card.saved, photo: card.photo)
      safe_join(out)
    end
  end

  def product_card_feature_button(listing, featured, options = {})
    feature_listing_button_and_modal(listing, featured,
      options.reverse_merge(button_options: {overlay: true, size: :small}))
  end

  def product_card_save_button(listing, collections, saved, options = {})
    save_listing_to_collection_button_and_modal(listing, collections, saved,
      options.reverse_merge(button_options: {overlay: true, size: :small}))
  end

  def product_card_v5_remove(card, options = {})
    out = []
    out << content_tag(:div, class: 'remove-btn-container') do
      link_to(feed_listing_path(card.listing.id), class: 'btn btn-overlay remove-btn transparent-btn',
              data: {method: :delete, remote: true, action: :remove}) do
        content_tag(:span, '', class: 'icons-button-remove')
      end
    end
    out << content_tag(:div, class: 'product-removed', data: {role: 'remove-ui'}) do
      out2 = []
      out2 << content_tag(:p, t('product_card.v5.removed.removed_copy'), class: 'product-title')
      safe_join(out2)
    end
    safe_join(out)
  end

  def product_card_v5_info(card, options = {})
    product_card_link_to_listing(card.listing, params: {src: options[:refer_source]}) do
      content_tag(:div, class: 'product-info') do
        content_tag(:span, card.listing.title, class: 'product-title ellipsis')
      end
    end
  end

  def product_card_v5_price(card, options = {})
    out = []
    out << content_tag(:div, class: 'price-box') do
      out2 = []
      out2 << product_card_link_to_listing(card.listing, params: {src: options[:refer_source]}) do
        content_tag(:div, class: 'price') do
          out3 = []
          out3 << tag(:hr)
          if card.listing.original_price?
            out3 << content_tag(:span, number_to_currency(card.listing.original_price), class: 'original-price')
          end
          out3 << number_to_currency(card.listing.price)
          safe_join(out3)
        end
      end
      safe_join(out2)
    end
    safe_join(out)
  end

  def product_card_remove_from_collection_button(card, options = {})
    content_tag(:div, class: 'remove-btn-container') do
      bootstrap_button(collection_listing_path(card.collection, card.listing),
                       class: 'btn-overlay remove-btn transparent-btn', remote: true,
                       method: :delete, data: {refresh: :self, role: 'remove-from-collection'}) do
        content_tag(:span, '', class: 'icons-button-remove')
      end
    end
  end

  def product_card_story(card, options = {})
    listing_social_story(card.story, card.likes, card.saves, options)
  end
end
