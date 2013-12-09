module Listings
  class FlaggedExhibit < Exhibitionist::Exhibit
    include Exhibitionist::RenderedWithHelper
    set_helper :listing_report_box
    set_virtual_path 'listings/show'

    def args
      [self, viewer, full_thanks: options[:full_thanks]]
    end
  end
end
