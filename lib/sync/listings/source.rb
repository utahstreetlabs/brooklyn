module Sync
  module Listings
    class Source
      include Enumerable

      class << self
        attr_accessor :seller_slug
        attr_accessor :pricing_version
        attr_accessor :categories

        def categories=(cmap)
          @categories = cmap.marshal_dump.each_with_object({}) do |(category,aliases),hash|
            aliases.each do |name|
              name = name.to_s.to_sym unless name.is_a?(Symbol)
              hash[name] = category
            end
          end
        end
      end
    end
  end
end
