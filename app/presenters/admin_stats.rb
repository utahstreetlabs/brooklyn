class AdminStats
  include Ladon::Logging

  attr_reader :stats
  delegate :[], :[]=, to: :stats

  def initialize
    @stats = {}
    @stats[:total_orders] = Order.count
    @stats[:orders_in_fulfillment] = Order.in_fulfillment.count
    @stats[:orders_in_checkout] = Order.in_checkout.count
    @stats[:settled_orders] = Order.settled.count
    @stats[:orders_new_this_month] = Order.new_this_month.count
    @stats[:orders_new_today] = Order.new_today.count
    @stats[:collections_new_this_month] = Collection.new_this_month.count
    @stats[:collections_new_today] = Collection.new_today.count
    @stats[:total_listings] = Listing.count
    @stats[:active_listings] = Listing.active.count
    @stats[:total_users] = User.count
    @stats[:registered_users] = User.registered.count
    @stats[:users_new_this_month] = User.new_this_month.count
    @stats[:users_new_today] = User.new_today.count
  end
end
