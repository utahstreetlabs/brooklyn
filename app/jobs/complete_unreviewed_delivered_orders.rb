require 'ladon'

class CompleteUnreviewedDeliveredOrders < Ladon::Job
  @queue = :orders

  def self.work
    Order.find_delivered_review_expired.each do |order|
      with_error_handling "completing unreviewed delivered order number #{order.id}" do
        logger.info("Autocompleting order #{order.id}")
        order.complete_and_attempt_to_settle!
      end
    end
  end
end
