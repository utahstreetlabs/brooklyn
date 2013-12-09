require 'orders/job_base'

module Orders
  class AfterFailureJob < JobBase
    @queue = :orders

    def self.work(id)
      with_error_handling("After failure of order #{id}") do
        order = CancelledOrder.find(id)
        inject_failure_notification_for_seller(order)
        inject_failure_notification_for_buyer(order)
      end
    end

    def self.inject_failure_notification_for_seller(order)
      inject_notification(:OrderFailed, order.listing.seller_id, order_id: order.id)
    end

    def self.inject_failure_notification_for_buyer(order)
      inject_notification(:OrderFailed, order.buyer_id, order_id: order.id)
    end
  end
end
