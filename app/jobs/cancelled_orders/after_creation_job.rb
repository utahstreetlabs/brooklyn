require 'orders/job_base'

module CancelledOrders
  class AfterCreationJob < Orders::JobBase
    @queue = :orders

    def self.work(id, options = {})
      with_error_handling("After cancellation of order #{id} with options #{options}") do
        order = CancelledOrder.find(id)
        create_feedback(order, options)
        email_buyer_order_cancelled(order)
        email_seller_order_cancelled(order)
        send_seller_hook(order, :deleted)
      end
    end

    def self.create_feedback(order, options)
      order.create_failed_transaction_feedback!(options[:failure_reason].to_sym) if options[:failure_reason]
    end

    def self.email_buyer_order_cancelled(order)
      send_email(:created_for_buyer, order) if order.was_confirmed_before_cancellation?
    end

    def self.email_seller_order_cancelled(order)
      send_email(:created_for_seller, order) if order.was_confirmed_before_cancellation?
    end
  end
end
