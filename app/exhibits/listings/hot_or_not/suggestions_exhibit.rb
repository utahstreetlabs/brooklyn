module Listings
  module HotOrNot
    class SuggestionsExhibit < Exhibitionist::Exhibit
      include Exhibitionist::RenderedWithCustom

      def initialize(suggestions, viewer, context, options = {})
        super(suggestions, viewer, context, options)
      end

      def to_json
        self.listings.map do |listing|
          {
            photo: context.listing_photo_tag(photos[listing.id], :medium),
            hotButton: context.listing_hot_button(listing),
            notButton: context.listing_not_button(listing)
          }
        end
      end

      custom_render do |exhibit|
        exhibit.to_json
      end
    end
  end
end
