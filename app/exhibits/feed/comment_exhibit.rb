module Feed
  class CommentExhibit < Exhibitionist::Exhibit
    include Exhibitionist::RenderedWithHelper
    set_helper :feed_card_comment
    set_virtual_path 'feed/show'
    attr_reader :comment

    def initialize(listing, comment, viewer, context)
      super(comment, viewer, context)
      @comment = comment
    end

    def args
      [comment, viewer]
    end
  end
end
