require 'brooklyn/sprayer'
require 'ladon'

# This job is intended to be queued up as a delayed job,
# 1 per order created in the system. As a result it does
# not need to query for purchased unshipped orders, instead
# getting the order id passed along.
class RemindPurchasedUnshippedOrder < Ladon::Job
  include Brooklyn::Sprayer

  @queue = :orders

  def self.work(order_id)
    with_error_handling("Remind seller of unshipped order #{order_id}") do
      order = Order.find(order_id)
      if order.confirmed?
        email_seller_order_purchased_unshipped(order)
        notify_seller_order_purchased_unshipped(order)
      end
    end
  end

  def self.email_seller_order_purchased_unshipped(order)
    send_email(:purchased_unshipped_reminder_for_seller, order)
  end

  def self.notify_seller_order_purchased_unshipped(order)
    inject_notification(:OrderUnshipped, order.listing.seller_id, order_id: order.id)
  end
end
