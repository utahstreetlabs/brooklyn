module AddHelper
  def add_modal
    bootstrap_modal('add', t('add.modal.add_listing.title'), show_footer: false, data: {role: 'add-modal', user: current_user.slug}) do
      out = []
      out << content_tag(:p) do
        t('add.modal.add_listing.instructions_html')
      end
      out << content_tag(:div, style: 'margin-bottom: 28px;') do
        out2 = []
        if feature_enabled?(:listings, :external)
          out2 << bootstrap_button(id: 'add-modal-add-from-web-button', type: :button,
                                   toggle_modal: 'add-modal-add-listing-from-web',
                                   data: {role: 'add-listing-from-web'}) do
            out3 = []
            out3 << bootstrap_image_tag('icons/add-listing-modal/add_from_web.png', :rounded, size: '75x75')
            out3 << tag(:br)
            out3 << t('add.modal.add_listing.from_web')
            safe_join(out3)
          end
        end
        out2 << bootstrap_button(new_listing_path, id: 'add-modal-add-listing-copious-button') do
          out3 = []
          out3 << bootstrap_image_tag('icons/add-listing-modal/add_listing.png', :rounded, size: '75x75')
          out3 << tag(:br)
          out3 << t('add.modal.add_listing.new_listing')
          safe_join(out3)
        end
        if feature_enabled?(:collections, :add)
          out2 << bootstrap_button(id: 'add-modal-add-collection-button', type: :button,
                                   toggle_modal: 'collection-create',
                                   data: {role: 'add-collection'}) do
            out3 = []
            out3 << bootstrap_image_tag('icons/add-listing-modal/add_collection.png', :rounded, size: '75x75')
            out3 << tag(:br)
            out3 << t('add.modal.add_listing.new_collection')
            safe_join(out3)
          end
        end
        safe_join(out2)
      end
      if feature_enabled?('listings.external.bookmarklet')
        out << content_tag(:div) do
          out2 = []
          out2 << external_bookmarklet_button
          out2 << content_tag(:p, class: 'small') do
            out3 = []
            out3 << t('add.modal.add_listing_bookmarklet.instructions_html')
            out3 << link_to_external_bookmarklet(current_user)
            safe_join(out3)
          end
          safe_join(out2)
        end
      end
      safe_join(out)
    end
  end

  def add_listing_from_web_modal
    bootstrap_modal('add-modal-add-listing-from-web', t('add.modal.add_listing_from_web.title'),
                    show_footer: false, remote: true) do
      out = []
      out << content_tag(:p) do
        t('add.modal.add_listing_from_web.instructions_html')
      end
      out << form_tag(listing_sources_path, method: :post, remote: true) do
        out2 = []
        out2 << text_field_tag(:url, nil, placeholder: t('add.modal.add_listing_from_web.url.placeholder'),
                                id: 'listing_source_url', autofocus: :autofocus)
        out2 << bootstrap_button(t('add.modal.add_listing_from_web.button.fetch'), type: :button, condition: :primary,
                                 disable_with: t('add.modal.add_listing_from_web.disable.fetch_html'),
                                 id: 'listing_source_url_button', data: {save: 'modal'})
        safe_join(out2)
      end
      safe_join(out)
    end
  end

  def link_to_external_bookmarklet(viewer, options = {})
    html_options = options.reverse_merge(
      id: 'add-modal-add-listing-external-bookmarklet-link',
      data: { created_at: Time.zone.now }
    )
    html_options[:data][:user] = viewer.slug if viewer
    link_to(t('add.modal.add_listing_bookmarklet.link'), info_extras_path, html_options)
  end
end
