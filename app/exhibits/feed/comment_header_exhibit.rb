module Feed
  class CommentHeaderExhibit < Exhibitionist::Exhibit
    include Exhibitionist::RenderedWithHelper
    set_helper :feed_card_comment_header
    set_virtual_path 'feed/show'

    def initialize(listing, viewer, context)
      super(listing, viewer, context)
    end

    def args
      [self, viewer]
    end
  end
end
