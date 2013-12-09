require 'ladon'

class CancelConfirmedUnshippedOrders < Ladon::Job
  @queue = :orders

  def self.work
    Order.find_confirmed_unshipped_to_be_cancelled.each do |order|
      with_error_handling "Failed to cancel unshipped order #{order.id}", {order_id: order.id} do
        cancel_unshipped_order(order)
      end
    end
  end

  def self.cancel_unshipped_order(order)
    order.failure_reason = Order::FailureReasons::NEVER_SHIPPED
    order.cancel!
  end
end
