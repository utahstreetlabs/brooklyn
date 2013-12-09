module Notifications
  module Tracking
    class NumberUpdatedExhibit < BaseExhibit
      include Exhibitionist::RenderedWithCustom

      custom_render do |exhibit, viewer|
        exhibit.render_notification(
          target: listing_url(exhibit.listing),
          body_text: nt(:user_html, scope: [:tracking, :number_updated], listing: exhibit.listing.title),
          left_image: copious_logo_image_tag,
          right_image: listing_photo_tag(exhibit.listing.photos.first, :xsmall, class: 'notification-target-image')
        )
      end
    end
  end
end
