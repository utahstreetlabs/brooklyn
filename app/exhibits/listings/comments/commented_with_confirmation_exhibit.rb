module Listings
  module Comments
    class CommentedWithConfirmationExhibit < Exhibitionist::Exhibit
      include Exhibitionist::RenderedWithCustom
      attr_reader :comment

      def initialize(listing, comment, viewer, context, options = {})
        super(listing, viewer, context, options)
        @comment = comment
      end

      custom_render do |listing|
        listing.options[:confirmation] || {}
      end
    end
  end
end
