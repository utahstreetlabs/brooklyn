module Admin
  module FeatureListsHelper
    def admin_feature_lists_modal_content(listing, feature_lists)
      content_tag(:div, data: {role: 'feature-list-modal'}) do
        bootstrap_form_tag(feature_on_feature_lists_admin_listing_path(listing.id), remote: true, horizontal: true,
          data: {type: :json}) do
          out = []
          feature_lists.sort_by { |fl| fl.name.downcase }.each do |feature_list|
            out << bootstrap_check_box_tag('feature_list_ids[]', feature_list.name, feature_list.id,
              listing.on_feature_list?(feature_list), id: "listing_featured_feature_list_ids_#{feature_list.id}")
          end
          safe_join(out)
        end
      end
    end

    def admin_feature_lists_featured_listings(feature_list, features)
      scope = "admin.feature_lists"
      out = []
      if features.any?
        out << t('reorder.header', scope: scope)
        out << bootstrap_table(condensed: true, data: {role: 'sortable-table'}) do
          out2 = []
          features.each do |feature|
            out2 << content_tag(:tr, id: "featured-listing-#{feature.listing.id}",
              data: {feature_list: feature_list.id, role: 'featured-listing',
                :'reorder-url' => reorder_admin_feature_list_featured_path(feature_list, feature)}) do
              out3 = []
              out3 << content_tag(:td, class: 'span2') do
                listing_photo_tag(feature.listing.photos.first, :small) if feature.listing.photos.first
              end
              out3 << content_tag(:td, class: 'span6') do
                link_to_listing(feature.listing)
              end
              out3 << content_tag(:td) do
                bootstrap_button_group do
                  bootstrap_button(nil, admin_feature_list_featured_path(feature_list, feature),
                    condition: :danger, size: :mini, icon: :remove, inverted_icon: true, rel: :tooltip,
                    title: t('reorder.remove.title', scope: scope, name: feature_list.name), remote: true,
                    data: {method: :delete, action: :delete, refresh: '[data-role=featured-listings]',
                      confirm: t('reorder.remove.confirm', scope: scope)})
                end
              end
              safe_join(out3)
            end
          end
          safe_join(out2)
        end
      else
        out << t("reorder.none.header_html", scope: scope)
        out << link_to(t("reorder.none.find", scope: scope), admin_listings_path)
      end
      safe_join(out)
    end
  end
end
