module Notifications
  module Listing
    class SaveExhibit < BaseExhibit
      if feature_enabled?('notifications.layout.v2')
        include Exhibitionist::RenderedWithCustom

        custom_render do |exhibit, viewer|
          seller_role = (exhibit.seller == viewer ? :seller_self : :seller_user)
          role = (exhibit.saver == viewer ? :self_html : :user_html)

          exhibit.render_notification(
            target: public_profile_collection_url(exhibit.collection.owner, exhibit.collection),
            body_text: nt(role, scope: [:listing, :saved, seller_role], listing: exhibit.listing.title,
              collection: exhibit.collection.name, saver: exhibit.saver.name),
            left_image: user_avatar_small(exhibit.saver),
            right_image: listing_photo_tag(exhibit.listing.photos.first, :xsmall, class: 'notification-target-image')
          )
        end
      else
        include Exhibitionist::RenderedWithHelper
        set_helper :notification_listing_save
      end
    end
  end
end
