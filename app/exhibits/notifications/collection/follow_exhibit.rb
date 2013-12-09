module Notifications
  module Collection
    class FollowExhibit < BaseExhibit
      if feature_enabled?('notifications.layout.v2')
        include Exhibitionist::RenderedWithCustom

        custom_render do |exhibit, viewer|
          owner_role = (exhibit.collection.owner == viewer ? :owner_self : :owner_user)
          role = (exhibit.follower == viewer ? :self_html : :user_html)
          listing = exhibit.collection.listings.first || exhibit.collection.owner.seller_listings.first

          options = {
            target: public_profile_collection_url(exhibit.collection.owner, exhibit.collection),
            body_text: nt(role, scope: [:collection, :follow, owner_role],
              collection: exhibit.collection.name, follower: exhibit.follower.name),
            left_image: user_avatar_small(exhibit.follower),
          }
          options[:right_image] = listing_photo_tag(listing.photos.first, :xsmall, class: 'notification-target-image') if listing
          exhibit.render_notification(options)
        end
      else
        include Exhibitionist::RenderedWithHelper
        set_helper :notification_collection_follow
      end
    end
  end
end
