require 'ladon'

module Shipments
  # Check with the shipping carrier service to see if shipped orders have been delivered or not.
  class CheckDeliveryStatusJob < Ladon::Job
    @queue = :shipments

    def self.work
      Shipment.find_delivery_checkable.find_each do |shipment|
        with_error_handling("Check delivery status", shipment: shipment.id) do
          begin
            shipment.check_and_update_delivery_status!
          rescue ActiveMerchant::Shipping::ResponseError => e
            # this often happens before the carrier has updated their site, so just chill
            unless shipment.created_at > 1.day.ago
              logger.warn("%s delivery status check for shipment %d failed with API error: %s" %
                [shipment.carrier_name, shipment.id, e])
            end
          end
        end
      end
    end
  end
end
