require 'orders/job_base'

module Orders
  class AfterStagingJob < JobBase
    @queue = :orders

    def self.work(id)
      with_error_handling("After staging of order #{id}") do
        order = Order.find(id)
        send_seller_hook(order)
      end
    end
  end
end
