require 'exhibitionist'

module NotificationsHelper
  def notification_rows(user_notifications)
    out = []
    user_notifications.by_date.each_pair do |d, notifications|
      out << content_tag(:div, data: {date: d.to_time.to_i}, class: 'date') do
        out2 = []
        out2 << content_tag(:h5, notification_datestamp(d))
        notifications.each do |notification|
          out2 << notification_wrapper(notification) do
            out3 = []
            out3 << content_tag(:div, class: 'details') do
              out4 = []
              out4 << notification_details(user_notifications, notification)
              out4 << content_tag(:span, notification_timestamp(notification), class: 'meta')
              safe_join(out4)
            end
            out3 << content_tag(:div, class: 'actions', data: {role: 'notification-actions'}) do
              link_to_clear_notification(notification)
            end
          safe_join(out3)
          end
        end
        safe_join(out2)
      end
    end
    out
  end

  def notification_datestamp(date)
    if date.year == Time.now.year
      date.to_date.strftime("%B %e")
    else
      date.strftime('%B %e, %Y')
    end
  end

  def notification_wrapper(notification, &block)
    notification_type = notification.class.name.demodulize.underscore.sub('_notification', '')
    data = {notification: notification.id, role: :notification, type: notification_type}
    data[:'notifications-v2'] = true if feature_enabled?('notifications.layout.v2')
    content_tag(:div, data: data,
      :class => 'notification', &block)
  end

  def notification_details(list, notification, options = {})
    viewer = current_user
    type = notification.class.name.demodulize.to_sym
    if notification.is_a?(Lagunitas::FollowNotification)
      if feature_enabled?('notifications.layout.v2')
        n = UserFollowNotification.new(notification)
        n.follower = list.users[notification.follower_id]
        exhibit = Notifications::User::BaseExhibit.factory(n, viewer, self, options) if n.complete?
      else
        follower = list.users[notification.follower_id]
        if follower
          partial = 'follow'
          locals = {follower: follower}
        end
      end
    elsif notification.is_a?(Lagunitas::CollectionFollowNotification)
      n = CollectionNotification.new(notification)
      n.collection = list.collections[notification.collection_id]
      n.follower = list.users[notification.follower_id]
      exhibit = Notifications::Collection::BaseExhibit.factory(n, viewer, self, options) if n.complete?
    elsif notification.is_a?(Lagunitas::ListingNotification)
      n = ListingNotification.factory(notification)
      n.listing = list.listings[notification.listing_id]
      n.collection = list.collections[notification.collection_id]
      n.seller = n.listing && list.users[n.listing.seller_id]
      n.commenter = list.users[notification.commenter_id]
      n.replier = list.users[notification.replier_id]
      n.liker = list.users[notification.liker_id]
      n.saver = list.users[notification.saver_id]
      exhibit = Notifications::Listing::BaseExhibit.factory(n, viewer, self, options) if n.complete?
    elsif notification.is_a?(Lagunitas::OrderNotification)
      n = OrderNotification.new(notification)
      n.order = list.orders[notification.order_id] || list.cancelled_orders[notification.order_id]
      n.listing = n.order && list.listings[n.order.listing_id]
      n.buyer = n.order && list.users[n.order.buyer_id]
      n.seller = n.listing && list.users[n.listing.seller_id]
      exhibit = Notifications::Order::BaseExhibit.factory(n, viewer, self, options) if n.complete?
    elsif notification.is_a?(Lagunitas::SellerPaymentNotification)
      n = SellerPaymentNotification.new(notification)
      n.seller_payment = list.seller_payments[n.payment_id]
      n.order = n.seller_payment && list.orders[n.seller_payment.order_id]
      n.listing = n.order && list.listings[n.order.listing_id]
      exhibit = Notifications::Seller::BaseExhibit.factory(n, viewer, self, options) if n.complete?
    elsif notification.is_a?(Lagunitas::OrderRatingNotification) && feature_enabled?(:feedback)
      rating = list.order_ratings[notification.rating_id]
      if rating
        order = rating.order_id ? list.orders[rating.order_id] : list.cancelled_orders[rating.cancelled_order_id]
        listing = list.listings[order.listing_id] if order
        if order && listing
          text = case type
          when :FeedbackIncreasedNotification then notification_feedback_increased(viewer, rating, order, listing)
          when :FeedbackDecreasedNotification then notification_feedback_decreased(viewer, rating, order, listing)
          else nil
          end
        end
      end
    elsif notification.is_a?(Lagunitas::InviteSentPileOnNotification)
      n = InviteSentNotification.new(notification)
      n.invitee_profile = list.profiles[notification.invitee_profile_id]
      n.inviter = list.users[notification.inviter_id]
      n.invited = n.inviter && n.inviter.registered?
      exhibit = Notifications::Invite::BaseExhibit.factory(n, viewer, self, options) if n.complete?
    elsif notification.is_a?(Lagunitas::CreditNotification)
      n = CreditNotification.new(notification)
      n.credit = list.credits[notification.credit_id]
      n.offer = n.credit && list.offers[n.credit.offer_id]
      exhibit = Notifications::Credit::BaseExhibit.factory(n, viewer, self, options) if n.complete?
    elsif notification.is_a?(Lagunitas::TrackingNumberUpdatedNotification)
      n = TrackingNumberNotification.new(notification)
      n.shipment = list.shipments[notification.shipment_id]
      n.order = n.shipment && list.orders[n.shipment.order_id]
      n.listing = n.order && list.listings[n.order.listing_id]
      if feature_enabled?('notifications.layout.v2')
        exhibit = Notifications::Tracking::BaseExhibit.factory(n, viewer, self, options) if n.complete?
      else
        text = tracking_number_updated(n)
      end
    else
      logger.debug("Unsupported notification type #{notification.class}")
    end
    if partial
      capture { render "/notifications/#{partial}", options.merge(locals) }
    elsif text
      text
    elsif exhibit
      exhibit.render
    end
  end

  def notification_timestamp(notification)
    notification.created_at.in_time_zone.strftime("%H:%M")
  end

  def link_to_clear_notification(notification)
    link_to image_tag('icons/close-content-hover.png'), notification_path(notification.id), :'data-remote' => true, :'data-method' => :DELETE,
      :'data-type' => :json, :rel => :nofollow, :title => 'Clear', :class => 'clear-notification',
      :'data-notification' => notification.id
  end

  # XXX Remove when the 'notifications.layout.v2' flag is enabled
  def notification_listing_save(notification, viewer, options = {})
    saver = (notification.saver == viewer ? 'You' : link_to_user_profile(notification.saver))
    listing_link = link_to_listing(notification.listing)
    collection_link = link_to_collection(notification.collection)
    nt(:listing_save, saver: saver, listing_link: listing_link, collection_link: collection_link)
  end

  def notification_collection_follow(notification, viewer, options = {})
    collection_link = link_to_collection(notification.collection)
    profile_link = link_to_user_profile(notification.follower)
    role = (notification.follower == viewer ? :self : :user)
    nt(role, scope: [:collection_follow], profile_link: profile_link, collection_link: collection_link)
  end

  def notification_feedback_increased(viewer, rating, order, listing)
    feedback_link = link_to_feedback(nt(:feedback_score, scope: :feedback), rating, viewer)
    role = rating.is_a?(SellerRating) ? :seller : :buyer
    nt(role, scope: [:feedback, :increased], feedback_link: feedback_link)
  end

  def notification_feedback_decreased(viewer, rating, order, listing)
    listing_link = link_to_listing(listing)
    reason = nt(rating.failure_reason, scope: [:feedback, :failure_reason], listing_link: listing_link)
    feedback_link = link_to_feedback(nt(:feedback_score, scope: :feedback), rating, viewer)
    role = rating.is_a?(SellerRating) ? :seller : :buyer
    nt(role, scope: [:feedback, :decreased], feedback_link: feedback_link, reason: reason)
  end

  # XXX Remove when the 'notifications.layout.v2' flag is enabled
  def tracking_number_updated(notification)
    nt(:update, scope: [:tracking], listing_link: link_to_listing(notification.listing)).html_safe
  end

  def nt(key, options = {})
    scope = [:exhibits, :notifications]
    more_scope = options.delete(:scope)
    scope += Array.wrap(more_scope) if more_scope
    t(key, options.merge(scope: scope)).html_safe
  end
end
