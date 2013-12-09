require 'orders/job_base'

module Orders
  class AfterShipmentJob < JobBase
    @queue = :orders

    def self.work(id)
      with_error_handling("After shipment of order #{id}") do
        order = Order.find(id)
        notify_buyer_order_shipped(order)
        email_buyer_order_shipped(order)
        email_seller_order_shipped(order)
        send_seller_hook(order)
      end
    end

    def self.notify_buyer_order_shipped(order)
      inject_notification(:OrderShipped, order.buyer_id, order_id: order.id)
    end

    def self.email_buyer_order_shipped(order)
      send_email(:shipped_for_buyer, order)
    end

    def self.email_seller_order_shipped(order)
      send_email(:shipped_for_seller, order)
    end

  end
end
