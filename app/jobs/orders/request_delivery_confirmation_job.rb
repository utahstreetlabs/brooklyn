require 'brooklyn/sprayer'
require 'ladon'

module Orders
  class RequestDeliveryConfirmationJob < Ladon::Job
    include Brooklyn::Sprayer

    @queue = :orders

    def self.work
      Order.find_each_to_request_delivery_confirmation do |order|
        with_error_handling("Requesting delivery confirmation for order #{order.id}", order_id: order.id) do
          order.request_delivery_confirmation!
        end
      end
    end
  end
end
