module CollectionCardHelper
  def collection_cards(cards, profile_user, options = {})
    content_tag(:div, data: {role: 'collection-cards'}) do
      out = []
      if logged_in? && current_user == profile_user
        out << content_tag(:ul, class: 'search-results row') do
          out2 = [add_collection_card(current_user)]
          out2.concat(cards.map {|card| collection_card(card)})
          safe_join(out2)
        end
      elsif cards.any?
        out << content_tag(:ul, class: 'search-results row') do
          out2 = cards.map {|card| collection_card(card)}
          safe_join(out2)
        end
      else
        out << content_tag(:p, class: 'empty-msg margin-right') do
          t('.empty', name: profile_user.firstname)
        end
      end
      safe_join(out)
    end
  end

  def collection_card(card, options = {})
    li_classes = %w(card-container collection-card)
    li_classes << 'logged_in' if logged_in?
    li_options = {
      id: "collection-card-#{card.collection.id}",
      class: class_attribute(li_classes),
      data: {
        card: 'collection',
        collection: card.collection.id,
        source: options[:source]
      }
    }
    content_tag(:li, li_options) do
        out = []
        out << content_tag(:div, class: 'product-image-container') do
          link_to(public_profile_collection_path(card.owner, card.collection)) do
            content_tag(:ul, class: 'thumbnails waffle-format') do
              out2 = []
              card.photos.each do |photo|
                out2 << content_tag(:li) do
                  listing_photo_tag(photo, :medium, size: '300x300', data: {role: 'listing-photo'})
                end
              end
              # we always want 5 li elements regardless of how many actual photos there are
              ((card.photos.size+1).upto(CollectionCard.listings_per_card)).each do
                out2 << content_tag(:li)
              end
              safe_join(out2)
            end
          end
        end
        out << content_tag(:div, class: 'product-info') do
          link_to(public_profile_collection_path(card.owner, card.collection)) do
            out3 = []
            out3 << content_tag(:span, class: 'product-title') do
              collection_card_title(card.collection)
            end
            safe_join(out3)
          end
        end
        out << content_tag(:div, class: 'social-story-container') do
          content_tag(:span, class: 'social-story', data: {role: 'social-story'}) do
            bar_separated(link_to(card.owner.name, public_profile_collection_path(card.owner, card.collection)),
                                  t('collection_card.listing_count', count: card.listing_count))
          end
        end
        out << content_tag(:div, class: 'price-box') do
          out5 = []
          out5 << link_to(public_profile_collection_path(card.owner, card.collection)) do
            content_tag(:div, class: 'actor-activities') do
              out6 = []
              out6 << tag(:hr)
              out6 << content_tag(:span, t('collection_card.follower_count', count:
                                           card.follower_count), class: 'actor-activities')
              safe_join(out6)
            end
          end
          safe_join(out5)
        end
        # If collection is owned by the current user, show the edit button.
        # Otherwise show the follow button.
        if logged_in?
          if card.owner == current_user
            if feature_enabled?('collections.edit')
              out << content_tag(:div, class: 'product-action-area') do
                content_tag(:span, class: 'edit-wrap') do
                  collection_edit_button(card.collection, listing_count: card.listing_count)
                end
              end
            end
          else
            if feature_enabled?('collections.follow')
              out << content_tag(:div, class: 'product-action-area') do
                content_tag(:span, class: 'follow-wrap') do
                  collection_follow_button(card.collection, card.following)
                end
              end
            end
          end
        end
        safe_join(out)
      end
  end

  def collection_follow_button(collection, following, options = {})
    if following
      button_class = %w(follow actioned)
      path = collection_unfollow_path(collection.id)
      role = 'collection-unfollow'
      method = :delete
      disable_html = t('collection_card.button.unfollow.disable_html')
    else
      button_class = %w(follow)
      path = collection_follow_path(collection.id)
      role = 'collection-follow'
      method = :put
      disable_html = t('collection_card.button.follow.disable_html')
    end
    button_class << options.delete(:class)
    button_options = {
      method: method,
      remote: true,
      class: class_attribute(button_class),
      disable_with: disable_html,
      action_type: :social,
      data: {
        role: role,
        refresh: :self,
        include_source: true
      }
    }.merge(options)
    bootstrap_button(path, button_options) do
        collection_follow_button_content(following)
    end
  end

  def collection_follow_button_content(following)
    # same structure as the function in listings_helper.rb/listing_love_button_content
    classes = %w(icons-button-follow)
    classes << 'actioned' if following
    out = []
    out << content_tag(:span, nil, class: class_attribute(classes), data: {role: 'follow-button-content'})
    out << (following ? t('collection_card.button.unfollow.label') : t('collection_card.button.follow.label'))
    safe_join(out)
  end

  def collection_edit_button(collection, options = {})
    modal_id = "edit-collection-#{collection.id}"
    out = []
    out << bootstrap_button(t('collection_card.button.edit.label'), '#', type: :button, toggle_modal: modal_id,
      action_type: :curatorial, data: { action: 'edit-collection' }, class: 'edit-btn btn-divider')
    out << bootstrap_modal(modal_id, t('collection_card.modal.edit_collection.title'), show_save: false,
      data: { role: 'collection-edit-modal', refresh: "[data-collection='#{collection.id}']"}, remote: true,
      show_close: false, custom_links: edit_collection_modal_buttons(collection), class: 'collection-edit-modal') do
      edit_collection_form(collection)
    end
    # The confirmation modal is at the same level as the primary modal so the first can be hidden
    # when the second is shown.
    out << delete_collection_confirm_modal(collection, options)
    safe_join(out)
  end

  def edit_collection_form(collection)
    bootstrap_form_for(collection, url: collection_path(collection.id), html: {method: :put}, remote: true) do |f|
      f.text_field(:name, placeholder: t('collection_card.modal.edit_collection.name.placeholder'),
        autofocus: :autofocus, maxlength: Collection::MAX_NAME_LENGTH, required: true)
    end
  end

  def edit_collection_modal_delete_button(collection, options = {})
    modal_id = "delete-collection-#{collection.id}"
    out = []
    out << bootstrap_button(t('collection_card.button.delete.label'), '#', toggle_modal: modal_id,
      data: {action: 'delete-collection'})
    safe_join(out, ' ')
  end

  def edit_collection_modal_buttons(collection, options = {})
    out = []
    out << edit_collection_modal_delete_button(collection, options)
    out << bootstrap_modal_save(options)
    safe_join(out, ' ')
  end

  def edit_collection_success_modal(collection)
    modal_options = {
      class: 'success-modal',
      data: {
        role: 'edit-collection-success-modal',
        auto_hide: true
      },
      show_success: true,
      show_save: false,
      show_footer: false,
    }
    listing = collection.listings.first || collection.owner.seller_listings.first
    more = listing ? listing.more_from_this_seller(limit: Collection.config.success_modal.listing_count) : []
    photos = ListingPhoto.find_primaries(more)
    bootstrap_modal("edit-collection-success-modal",
                    t('controllers.collections.edit.success_modal.title'), modal_options) do
      out = []
      if more.any?
        out << content_tag(:p) do
          t('controllers.collections.edit.success_modal.more_from_seller', seller: listing.seller.name)
        end
        out << content_tag(:ul, class: 'pull-left thumbnails') do
          out2 = []
          more.each do |l|
            if photos.key?(l.id)
              out2 << content_tag(:li) do
                link_to(listing_photo_tag(photos[l.id], :medium), listing_path(l), class: 'thumbnail')
              end
            end
          end
          safe_join(out2)
        end
      end
      safe_join(out)
    end
  end

  def delete_collection_confirm_modal_buttons(collection, options = {})
    out = []
    out << bootstrap_modal_close(options.merge(close_button_text: t('collection_card.button.cancel.label')))
    out << bootstrap_button(t('collection_card.button.delete.label'), collection_path(collection.id),
      method: :delete, remote: true, condition: :danger, data: {action: 'delete-collection',
      refresh: "[data-role=collection-cards]"})
    safe_join(out, ' ')
  end

  def delete_collection_confirm_modal(collection, options = {})
    delete_modal_id = "delete-collection-#{collection.id}"
    out = []
    out << bootstrap_modal(delete_modal_id, t('collection_card.modal.delete_collection_confirm.title'), show_save:
                          false, data: { role: 'collection-edit-modal-delete' }, remote: true, show_close: false,
                          custom_links: delete_collection_confirm_modal_buttons(collection), class:
                          'collection-delete-modal') do
      t('collection_card.modal.delete_collection_confirm.content',
        num: (options[:listing_count] || collection.listing_count), name: collection.name)
    end
    safe_join(out, ' ')
  end

  def collection_card_title(collection)
    content_tag(:span, collection.name, class: 'product-title ellipsis', data: { role: 'collection-title' })
  end

  def add_collection_card(viewer)
    li_classes = %w(card-container collection-card)
    li_classes << 'logged_in' if logged_in?
    content_tag(:li, id: 'add-collection-card', class: class_attribute(li_classes),
                data: {role: 'add-collection-card', source: 'add-collection-card', user: viewer.slug}) do
      bootstrap_button(type: :button, data: {role: 'add-collection-card-button'},
                       toggle_modal: 'collection-create', class: 'add-card-link btn-link') do
        out = []
        out << content_tag(:div, class: 'product-image-container') do
          content_tag(:div, class: 'add-placeholder') do
            content_tag(:div, '', class: 'icons-large-add-collection')
          end
        end
        out << content_tag(:div, class: 'card-cta') do
          content_tag(:div, t('add_collection_card.button.add.label'), id: 'add-collection-card-button',
                      role: 'add-collection-card-button', class: 'btn btn-primary btn-small curatorial')
        end
        safe_join(out)
      end
    end
  end

  def collection_add_listing_card(viewer)
    li_classes = %w(card-container listing-card)
    li_classes << 'logged_in' if logged_in?
    content_tag(:li, id: 'add-listing-card', class: class_attribute(li_classes),
                data: {role: 'add-listing-card'}) do
      bootstrap_button(type: :button, data: {source: 'add-listing-card', user: viewer.slug,
                       role: 'add-widget'}, toggle_modal: 'add', class: 'add-card-link btn-link') do
        out = []
        out << content_tag(:div, class: 'product-image-container') do
          content_tag(:div, class: 'add-placeholder') do
            content_tag(:div, '', class: 'icons-large-add-listing')
          end
        end
        out << content_tag(:div, class: 'card-cta') do
          content_tag(:div, t('add_listing_card.button.add.label'), id: 'add-listing-card-button',
                      role: 'add-widget', class: 'btn btn-primary btn-small curatorial')
        end
        safe_join(out)
      end
    end
  end
end
