module Listings
  class LovedExhibit < Exhibitionist::Exhibit
    include Exhibitionist::RenderedWithCustom

    attr_reader :like

    def initialize(listing, like, viewer, context)
      super(listing, viewer, context)
      @like = like
    end

    custom_render do |exhibit|
      loves = exhibit.likes_summary
      {
        button: Listings::LoveButtonExhibit.new(exhibit, exhibit.like, exhibit.viewer, self).render,
        love_box: Listings::LoveBoxExhibit.new(exhibit, loves, exhibit.viewer, self).render,
        stats: exhibit.context.listing_stats(exhibit.likes_count, exhibit.saves_count),
        loved: true,
        listingId: exhibit.id
      }
    end
  end
end
