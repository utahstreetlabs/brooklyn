module Sync
  module Listings
    class Adapter
      attr_accessor :uid, :title, :description, :price, :shipping, :category_slug, :photo_files,
        :pricing_version, :tag_names, :tag_names_no_create, :condition

      def attributes
        { title: title, description: description, price: price, shipping: shipping, tag_names: tag_names }
      end
    end
  end
end
