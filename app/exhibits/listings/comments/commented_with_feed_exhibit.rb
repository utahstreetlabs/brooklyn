module Listings
  module Comments
    class CommentedWithFeedExhibit < Exhibitionist::Exhibit
      include Exhibitionist::RenderedWithHelper
      set_helper :listing_comment
      set_virtual_path 'listings/show'
      attr_reader :comment, :feed

      def initialize(listing, comment, viewer, context, options = {})
        super(listing, viewer, context, options)
        @comment = comment
        comments = [comment]
        comments << options[:original_comment] if options[:original_comment]
        @feed = ListingFeed.new(listing, comments)
      end

      def args
        [feed, comment, viewer]
      end
    end
  end
end
