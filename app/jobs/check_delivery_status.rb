require 'ladon'

# XXX: replaced by Shipments::CheckDeliveryStatusJob. remove after prepaid shipping ships.
class CheckDeliveryStatus < Ladon::Job
  @queue = :orders

  def self.work
    Shipment.check_all_delivery_statuses
  end
end
