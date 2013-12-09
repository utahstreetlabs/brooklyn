require 'lagunitas/resource/notifications'
require 'rubicon/models/profile'

class UserNotifications
  include Ladon::Logging

  attr_reader :user, :by_date, :all, :order_ratings, :orders, :cancelled_orders, :listings, :users, :profiles, :credits,
    :offers, :shipments, :seller_payments, :collections, :page_manager

  def initialize(user, options = {})
    @user = user

    options = options.reverse_merge(mark_viewed: true)
    user_notifications = @user.recent_notifications(options)
    values = user_notifications.find_all { |n| displayable?(n) }
    @page_manager = user_notifications

    # Eager fetch the associated models. Be sure to use AR where rather than find so that we ignore models that no
    # longer exist.

    collection_ids = []
    order_ids = []
    cancelled_order_ids = []
    rating_ids = []
    listing_ids = []
    user_ids = []
    profile_ids = []
    credit_ids = []
    shipment_ids = []
    seller_payment_ids = []
    values.each do |notification|
      rating_ids << notification.rating_id if notification.respond_to?(:rating_id)
      if notification.respond_to?(:order_id)
        if notification.is_a?(Lagunitas::OrderFailedNotification)
          cancelled_order_ids << notification.order_id
        else
          order_ids << notification.order_id
        end
      end
      collection_ids << notification.collection_id if notification.respond_to?(:collection_id)
      listing_ids << notification.listing_id if notification.respond_to?(:listing_id)
      user_ids << notification.liker_id if notification.respond_to?(:liker_id)
      user_ids << notification.saver_id if notification.respond_to?(:saver_id)
      user_ids << notification.follower_id if notification.respond_to?(:follower_id)
      user_ids << notification.inviter_id if notification.respond_to?(:inviter_id)
      user_ids << notification.commenter_id if notification.respond_to?(:commenter_id)
      user_ids << notification.replier_id if notification.respond_to?(:replier_id)
      profile_ids << notification.invitee_profile_id if notification.respond_to?(:invitee_profile_id)
      credit_ids << notification.credit_id if notification.respond_to?(:credit_id)
      shipment_ids << notification.shipment_id if notification.respond_to?(:shipment_id)
      seller_payment_ids << notification.payment_id if notification.respond_to?(:payment_id)
    end

    @collections = Collection.where(id: collection_ids.compact.uniq).inject({}) {|m, c| m.merge(c.id => c)}

    @shipments = Shipment.where(id: shipment_ids.compact.uniq).inject({}) {|m, c| m.merge(c.id => c)}
    order_ids.concat(@shipments.values.map(&:order_id))

    @order_ratings = OrderRating.where(id: rating_ids.compact.uniq).inject({}) {|m, r| m.merge(r.id => r)}

    order_ids.concat(@order_ratings.values.map(&:order_id))
    @orders = Order.where(id: order_ids.compact.uniq).inject({}) {|m, o| m.merge(o.id => o)}

    cancelled_order_ids.concat(@order_ratings.values.map(&:cancelled_order_id))
    @cancelled_orders = CancelledOrder.where(id: cancelled_order_ids.compact.uniq).
      inject({}) {|m, o| m.merge(o.id => o)}

    listing_ids.concat(@orders.values.map(&:listing_id))
    listing_ids.concat(@cancelled_orders.values.map(&:listing_id))
    @listings = Listing.where(id: listing_ids.compact.uniq).inject({}) {|m, l| m.merge(l.id => l)}

    user_ids.concat(@order_ratings.values.map(&:user_id))
    user_ids.concat(@orders.values.map(&:buyer_id))
    user_ids.concat(@cancelled_orders.values.map(&:buyer_id))
    user_ids.concat(@listings.values.map(&:seller_id))
    @users = User.where(id: user_ids.compact.uniq).inject({}) {|m, u| m.merge(u.id => u)}

    @profiles = Profile.find(profile_ids.compact.uniq).inject({}) {|m, p| m.merge(p.id => p)}

    @credits = Credit.where(id: credit_ids.compact.uniq).inject({}) {|m, c| m.merge(c.id => c)}

    offer_ids = @credits.values.map(&:offer_id).compact.uniq
    @offers = offer_ids.any?? Offer.where(id: offer_ids).inject({}) {|m, o| m.merge(o.id => o)} : {}

    @seller_payments = if seller_payment_ids.any?
      SellerPayment.where(id: seller_payment_ids).inject({}) {|m, p| m.merge(p.id => p)}
    else
      {}
    end

    @all = values
    @by_date = @all.group_by {|n| n.created_at.in_time_zone.to_date}
  end

  # short term hack to suppress notifications that the view layer doesn't know how to render. will be replaced when
  # this presenter is rewritten using modern patterns.
  def displayable?(notification)
    type = notification.class.name.demodulize.to_sym
    return false if type == :OrderUnratedNotification
    unless feature_enabled?(:feedback)
      return false if type == :FeedbackIncreasedNotification
      return false if type == :FeedbackDecreasedNotification
    end
    true
  end
end
