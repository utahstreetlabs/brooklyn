module Listings
  class LoveButtonExhibit < Exhibitionist::Exhibit
    include Exhibitionist::RenderedWithHelper
    set_helper :listing_love_button
    set_virtual_path 'listings/show'
    attr_reader :loved

    def initialize(listing, loved, viewer, context)
      super(listing, viewer, context)
      @loved = !!loved
    end

    def args
      [self, loved]
    end
  end
end
