require 'ladon'
require 'order_hooks'

class Hooks::PublishOrderChange < Ladon::Job
  @queue = :hooks

  def self.work(order_id, type)
    with_error_handling("publish order change", order_id: order_id) do
      order = begin
        Order.find(order_id)
      rescue ActiveRecord::RecordNotFound
        CancelledOrder.find(order_id)
      end
      OrderHooks.fire(order, type.to_sym)
    end
  end
end
