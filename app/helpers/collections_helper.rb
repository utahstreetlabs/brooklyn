module CollectionsHelper
  def link_to_collection(collection)
    link_to(collection.name, public_profile_collection_path(collection.owner, collection))
  end

  def create_collection_modal
    bootstrap_modal('collection-create', t('collections.create.modal.title'), remote: true,
                    save_button_text: t('collections.create.modal.button.add'), show_close: false,
                    data: {include_source: true}) do # source is added dynamically with js
      create_collection_modal_content(Collection.new)
    end
  end

  def create_collection_modal_content(collection)
    bootstrap_form_for(collection, remote: true) do |f|
      f.text_field(:name, placeholder: t('collections.create.modal.name.placeholder'), autofocus: :autofocus,
                   maxlength: Collection::MAX_NAME_LENGTH, required: true)
    end
  end


  def create_collection_listings_modal(collection, suggested_listings)
    bootstrap_modal('collection-create-listings', t('collections.create.listings_modal.title'),
                    scrollable_body: true, remote: true, show_close: false,
                    save_button_text: t('collections.create.listings_modal.button.save.label'),
                    data: {role: 'collection-create-listings-modal', include_source: true,
                           source: 'collection-create-listings-modal'}, show_success: true) do
      bootstrap_form_tag(populate_collection_path(collection.id), method: :post, remote: true, data: {primary: true},
                         id: "collection-create-listings-form") do
        out = []
        if suggested_listings.any?
          out << content_tag(:p) do
            t('collections.create.listings_modal.instructions_html', collection: collection.name)
          end
          out << content_tag(:ul, class: 'pull-left thumbnails') do
            out2 = []
            suggested_listings.each do |listing|
              out2 << content_tag(:li, class: 'thumbnail', data: {listing: listing.id, role: 'selectable'}) do
                out3 = []
                out3 << listing_photo_tag(listing.photos.first, :medium)
                out3 << content_tag(:div, class: 'selected-overlay') do
                  content_tag(:span, '', class: 'icons-checkmark')
                end
                out3 << check_box_tag('listing_id[]', listing.id, false, id: "listing_id_#{listing.id}",
                                      style: 'display:none')
                safe_join(out3)
              end
            end
            safe_join(out2)
          end
        end
        safe_join(out)
      end
    end
  end

  def create_collection_success_modal(collection, interesting_listings)
    bootstrap_modal('collection-create-success', t('collections.create.success_modal.title'), class: 'success-modal',
                    data: {role: 'collection-create-success-modal', auto_hide: true},
                    show_save: false, show_footer: false, show_success: true) do
      out = []
      if interesting_listings.any?
        out << content_tag(:p) do
          t('collections.create.success_modal.instructions_html')
        end
        out << content_tag(:ul, class: 'pull-left thumbnails') do
          out2 = []
          interesting_listings.each do |listing|
            out2 << content_tag(:li) do
              link_to(listing_photo_tag(listing.photos.first, :medium), listing_path(listing), class: 'thumbnail')
            end
          end
          safe_join(out2)
        end
      end
      safe_join(out)
    end
  end

  def collection_dropdown_item(collection)
    bootstrap_list_items([[collection.name,
      public_profile_collection_path(current_user.id, collection.slug), data: {:'collection-id' => collection.slug}]])
  end

  def collection_dropdown_menu(collections)
    bootstrap_dropdown_menu(save_listing_to_collection_list(collections))
  end

  def new_collection_input_and_button
    content_tag(:div, class: 'input-append', data: {role: 'name-input'}) do
      out = []
      out << text_field(:add_collection_input, nil, placeholder:
                        t('listings.save_to_collection.modal.new_collection.placeholder_html'),
                        class: 'add-new-collection-input', data: {role: 'collection-name'},
                        maxlength: Collection::MAX_NAME_LENGTH)
      out << bootstrap_button(t('listings.save_to_collection.button.add.text'), nilhref,
                              data: {action: 'add-collection'}, class: 'btn-regular-submit',
                              disable_with: t('listings.save_to_collection.button.add.disable_html'))
      safe_join(out)
    end
  end
end
