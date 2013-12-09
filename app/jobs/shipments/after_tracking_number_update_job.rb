require 'brooklyn/sprayer'
require 'ladon'

module Shipments
  class AfterTrackingNumberUpdateJob < Ladon::Job
    include Brooklyn::Sprayer

    @queue = :shipments

    def self.work(id)
      with_error_handling("After tracking number updated for shipment #{id}") do
        shipment = Shipment.find(id)
        # the only known circumstance for a prepaid shipping order's tracking number to change is when the shipping
        # label expires and the seller is forced to fall back to basic shipping. we definitely don't want to send
        # notifications in that case (the buyer doesn't care, and the seller would be confused by "your tracking
        # number changed" as opposed to "your shipping label expired" [which we'll add support for eventually]).
        # be defensive and never send notifications for prepaid shipping orders.
        send_notifications(shipment) unless shipment.order.listing.prepaid_shipping?
      end
    end

    def self.email_buyer_tracking_number_updated(shipment)
      send_email(:tracking_number_updated_for_buyer, shipment)
    end

    def self.email_seller_tracking_number_updated(shipment)
      send_email(:tracking_number_updated_for_seller, shipment)
    end

    def self.notify_buyer_tracking_number_updated(shipment)
      notify_tracking_number_updated(shipment.order.buyer, shipment)
    end

    def self.notify_seller_tracking_number_updated(shipment)
      notify_tracking_number_updated(shipment.order.listing.seller, shipment)
    end

    def self.notify_tracking_number_updated(user, shipment)
      inject_notification(:TrackingNumberUpdated, user.id, shipment_id: shipment.id,
                          tracking_number: shipment.tracking_number)
    end

    def self.send_notifications(shipment)
      email_buyer_tracking_number_updated(shipment)
      email_seller_tracking_number_updated(shipment)
      notify_buyer_tracking_number_updated(shipment)
      notify_seller_tracking_number_updated(shipment)
    end
  end
end
