module Listings
  class UnlovedExhibit < Exhibitionist::Exhibit
    include Exhibitionist::RenderedWithCustom

    custom_render do |exhibit|
      loves = exhibit.likes_summary
      {
        button: Listings::LoveButtonExhibit.new(exhibit, false, exhibit.viewer, self).render,
        love_box: Listings::LoveBoxExhibit.new(exhibit, loves, exhibit.viewer, self).render,
        stats: exhibit.context.listing_stats(exhibit.likes_count, exhibit.saves_count),
        loved: false,
        listingId: exhibit.id
      }
    end
  end
end
