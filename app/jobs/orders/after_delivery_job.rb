require 'orders/job_base'

module Orders
  class AfterDeliveryJob < JobBase
    @queue = :orders

    def self.work(id)
      with_error_handling("After delivery of order #{id}") do
        order = Order.find(id)
        notify_buyer_order_delivered(order)
        email_buyer_order_delivered(order)
        notify_seller_order_delivered(order)
        email_seller_order_delivered(order)
        send_seller_hook(order)
      end
    end

    def self.notify_buyer_order_delivered(order)
      inject_notification(:OrderDelivered, order.buyer_id, order_id: order.id)
    end

    def self.email_buyer_order_delivered(order)
      send_email(:delivered_for_buyer, order)
    end

    def self.notify_seller_order_delivered(order)
      inject_notification(:OrderDelivered, order.listing.seller_id, order_id: order.id)
    end

    def self.email_seller_order_delivered(order)
      send_email(:delivered_for_seller, order)
    end
  end
end
