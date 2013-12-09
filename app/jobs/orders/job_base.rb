require 'brooklyn/sprayer'
require 'ladon'

module Orders
  class JobBase < Ladon::Job
    include Brooklyn::Sprayer

    def self.send_seller_hook(order, type = :updated)
      order.send_hook_to_api_seller(type)
    end
  end
end
