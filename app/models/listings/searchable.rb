require 'active_support/concern'

module Listings
  module Searchable
    extend ActiveSupport::Concern

    included do

      searchable auto_index: false, if: :visible? do
        text :title, boost: 1.5, more_like_this: true

        text :description, more_like_this: true do
          self.class.html_helper.strip_tags(description)
        end

        text :seller_name do
          seller.name if seller.present?
        end

        text :category_name, boost: 3.0, more_like_this: true do
          category.name if category.present?
        end

        text :tag_names, boost: 2.0, more_like_this: true do
          tags.map { |tag| tag.primary.name }.uniq
        end

        text :brand_name, boost: 2.0, more_like_this: true do
          brand.name if brand_id
        end

        text :condition_names do
          dimension_values.map { |dv| dv.value }
        end

        integer :likes do
          persisted?? self.likes_count : 0
        end

        # used for filtering
        string :category_slug do
          category.slug if category.present?
        end
        string :category_facet do
          "#{category.slug}##{category.name}" if category.present?
        end
        string :tag_slugs, multiple: true do
          tags.map { |t| t.primary.slug }.uniq
        end
        string :tag_facets, multiple: true do
          tags.map { |t| t.primary }.uniq.map { |t| "#{t.slug}##{t.name.titlecase}" }
        end
        string :brand_slug do
          brand.slug if brand_id
        end
        string :brand_facet do
          "#{brand.slug}##{brand.name.titlecase}" if brand_id
        end
        string :size_slug do
          size.slug if size_id
        end
        string :size_facet do
          "#{size.slug}##{size.name.titlecase}" if size_id
        end
        string :condition_slug do
          dv = condition_dimension_value
          dv && dv.id
        end
        string :condition_facet do
          dv = condition_dimension_value
          dv && "#{dv.id}##{dv.value}"
        end
        integer :seller_id, :references => User
        string :state
        boolean :approved
        time :approved_at

        #used for sorting
        time :created_at
        float :price

        # DEPRECATED FILTERING ATTRIBUTES
        # these can be removed after prod roll
        # needed so old brooklyn can run on re-indexed solr until the roll happens
        integer :category_id, :references => Category
        integer :tag_ids, :references => Tag, :multiple => true do
          tags.map { |tag| tag.primary.id }.uniq
        end
        integer :brand_id, references: Tag
        integer :size_id, references: Tag
        integer :dimension_value_ids, :references => DimensionValue, :multiple => true
      end
    end
  end
end
