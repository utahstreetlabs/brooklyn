module Listings
  module FeatureModalHelper
    def feature_listing_modal_id(suffix = nil, options = {})
      id = ['feature']
      id << suffix if suffix
      id.join('-')
    end

    def feature_listing_button_and_modal(listing, featured, options = {})
      out = []
      out << feature_listing_button(listing, featured, options)
      out << feature_listing_modal(listing, options)
      safe_join(out)
    end

    def feature_listing_button(listing, featured, options = {})
      modal_id = options[:id] || feature_listing_modal_id(listing.id, options)
      button_options = options.fetch(:button_options, {}).reverse_merge(
        type: :button,
        action_type: :curatorial,
        actioned: featured,
        toggle_modal: modal_id,
        data: {
          action: 'feature',
          role: "feature-listing-#{listing.id}",
          disable_with: t('listings.feature.button.disable_html')
        }
      )
      out = []
      out << bootstrap_button(button_options) do
        out2 = []
        out2 << content_tag(:span, nil, class: 'icons-button-save')
        out2 << t("listings.feature.button.#{featured ? 'featured' : 'feature'}.text")
        safe_join(out2)
      end
      safe_join(out)
    end

    def feature_listing_modal(listing, options = {})
      id = options[:id] || feature_listing_modal_id(listing.id, options)
      out = []
      out << bootstrap_modal(id, t('listings.feature.modal.title'),
                             data: {role: 'feature-manager', include_source: true,
                             url: feature_modal_listing_features_path(listing)},
                             remote: true, show_close: false,
                             refresh: "[data-role=feature-listing-#{listing.id}]", class: 'feature-listing-modal') do
      end
      safe_join(out)
    end

    def feature_listing_modal_contents(listing, options = {})
      out = []
      id = options[:id] || feature_listing_modal_id(listing.id, options)
      out << content_tag(:div, class: 'product-image-container') do
        listing_photo_tag(options[:photo] || listing.photos.first, :px_220x220, title: listing.title,
                          class: 'product-image')
      end
      out << feature_listing_form(id, listing)
      safe_join(out)
    end

    def feature_listing_form(id, listing)
      bootstrap_form_tag(listing_features_path(listing), method: :put, remote: true,
        class: 'listing-feature', id: "#{id}-form", data: {role: 'listing-feature-form'}) do
        out = []
        out << feature_listing_multi_selector(listing)
        safe_join(out)
      end
    end

    def feature_listing_multi_selector(listing, options = {})
      all_tags = listing.tags.sort_by {|t| t.name.downcase }
      all_feature_lists = FeatureList.all.sort_by {|fl| fl.name.downcase }
      content_tag(:div, data: {role: 'multi-selector'}, class: 'well well-small well-border') do
        out = []
        out << content_tag(:div, class: 'well-header well-header-small') do
          content_tag(:div, data: {role: 'selectables'}, class: 'multi-selector') do
            out2 = []
            all_feature_lists.each do |feature_list|
              selected = listing.on_feature_list?(feature_list)
              out2 << feature_list_listing_selectable(feature_list, selected)
            end
            out2 << category_listing_selectable(listing.category, listing.category_feature.present?)
            all_tags.each do |tag|
              selected = listing.featured_in_tags.include?(tag)
              out2 << tag_listing_selectable(tag, selected)
            end
            safe_join(out2)
          end
        end
        safe_join(out)
      end
    end

    def category_listing_selectable(category, selected = false)
      bootstrap_check_box_tag("category_id", category.name, category.id, selected)
    end

    def feature_list_listing_selectable(feature_list, selected = false)
      bootstrap_check_box_tag("feature_list_ids[]", feature_list.name, feature_list.id, selected)
    end

    def tag_listing_selectable(tag, selected = false)
      bootstrap_check_box_tag("tag_ids[]", tag.name, tag.id, selected)
    end

    def feature_listing_success_modal(listing)
      modal_options = {
        class: 'success-modal',
        show_success: true,
        show_save: false,
        data: {
          role: 'feature-listing-success-modal',
          auto_hide: true
        }
      }
      bootstrap_modal("listing-feature-success-#{listing.id}",
                      t('listings.feature.success_modal.title'), modal_options) do
        out = []
        if listing.features.any?
          features = []
          features += listing.featured_in_feature_lists.map(&:name)
          features += [listing.category_feature.featurable.name] if listing.category_feature
          features += listing.featured_in_tags.map(&:name)
          out << t('listings.feature.success_modal.featured_in', features: features.join(', '))
        else
          out << t('listings.feature.success_modal.no_features')
        end
        safe_join(out)
      end
    end
  end
end
