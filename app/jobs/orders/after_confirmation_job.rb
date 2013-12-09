require 'orders/job_base'
require 'remind_purchased_unshipped_order'

module Orders
  class AfterConfirmationJob < JobBase
    @queue = :orders

    def self.work(id)
      with_error_handling("After confirmation of order #{id}") do
        order = Order.find(id)
        email_buyer_order_created(order)
        notify_seller_order_created(order)
        email_seller_order_created(order)
        schedule_handling_reminder(order)
        send_seller_hook(order)
      end
    end

    def self.email_buyer_order_created(order)
      send_email(:purchased_for_buyer, order)
    end

    def self.notify_seller_order_created(order)
      inject_notification(:OrderCreated, order.listing.seller_id, order_id: order.id)
    end

    def self.email_seller_order_created(order)
      send_email(:purchased_for_seller, order)
    end

    def self.schedule_handling_reminder(order)
      handling_reminder_after = order.handling_reminder_after
      if handling_reminder_after
        RemindPurchasedUnshippedOrder.enqueue_in(handling_reminder_after, order.id)
      end
    end
  end
end
