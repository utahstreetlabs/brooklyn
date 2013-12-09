require 'ladon'

class ExpireOrders < Ladon::Job
  @queue = :orders

  def self.work(timeout)
    Order.find_expired(timeout).each do |order|
      with_error_handling("expire order", order_id: order.id) do
        order.cancel_if_unconfirmed!
      end
    end
  end
end
