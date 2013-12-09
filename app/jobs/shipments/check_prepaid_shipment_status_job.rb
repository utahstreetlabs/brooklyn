require 'ladon'

module Shipments
  # Check with the shipping label service to see if confirmed prepaid shipping orders have shipped or not.
  class CheckPrepaidShipmentStatusJob < Ladon::Job
    @queue = :shipments

    def self.work
      Shipment.find_prepaid_shipment_checkable.find_each do |shipment|
        begin
          shipment.check_and_update_prepaid_shipment_status!
        rescue Brooklyn::ShippingLabels::ShippingLabelException => e
          # service failures that we can't do anything about
          logger.warn("Checking prepaid shipment status for shipment #{shipment.id} failed: #{e}")
        rescue Exception => e
          handle_error("Check prepaid shipment status", e, shipment: shipment.id)
        end
      end
    end
  end
end
