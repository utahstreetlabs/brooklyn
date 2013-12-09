module Listings
  class LoveBoxExhibit < Exhibitionist::Exhibit
    include Exhibitionist::RenderedWithHelper
    set_helper :listing_love_box
    set_virtual_path 'listings/show'
    attr_reader :likes_summary

    def initialize(listing, likes_summary, viewer, context)
      super(listing, viewer, context)
      @likes_summary = likes_summary
    end

    def args
      [likes_summary, viewer]
    end
  end
end
