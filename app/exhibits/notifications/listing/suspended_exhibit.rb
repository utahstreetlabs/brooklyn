module Notifications
  module Listing
    class SuspendedExhibit < BaseExhibit
      if feature_enabled?('notifications.layout.v2')
        include Exhibitionist::RenderedWithCustom

        custom_render do |exhibit, viewer|
          exhibit.render_notification(
            target: Brooklyn::Application.config.urls.listing_guidelines,
            body_text: nt(:self_html, scope: [:listing, :suspended], listing: exhibit.listing.title),
            left_image: copious_logo_image_tag,
            right_image: listing_photo_tag(exhibit.listing.photos.first, :xsmall, class: 'notification-target-image')
          )
        end
      else
        include Exhibitionist::RenderedWithPartial
        set_partial '/notifications/listing_suspended'
      end
    end
  end
end
