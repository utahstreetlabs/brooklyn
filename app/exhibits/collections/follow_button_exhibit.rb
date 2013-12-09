module Collections
  class FollowButtonExhibit < Exhibitionist::Exhibit
    include Exhibitionist::RenderedWithHelper
    set_helper :collection_follow_button
    set_virtual_path 'collections/follow'
    attr_reader :following

    def initialize(listing, following, viewer, context)
      super(listing, viewer, context)
      @following = following
    end

    def args
      [self, following]
    end
  end
end
