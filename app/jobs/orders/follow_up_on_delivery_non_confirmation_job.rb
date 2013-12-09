require 'ladon'

module Orders
  class FollowUpOnDeliveryNonConfirmationJob < Ladon::Job
    include Brooklyn::Sprayer

    @queue = :orders

    def self.work
      Order.find_each_to_follow_up_on_delivery_non_confirmation do |order|
        with_error_handling("Following up on delivery confirmation for order #{order.id}", order_id: order.id) do
          order.follow_up_on_delivery_non_confirmation!
        end
      end
    end
  end
end
