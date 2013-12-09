require 'orders/job_base'

module Orders
  class AfterCreationJob < JobBase
    @queue = :orders

    def self.work(id)
      with_error_handling("After creation of order #{id}") do
        order = Order.find(id)
        send_seller_hook(order, :created)
      end
    end
  end
end
