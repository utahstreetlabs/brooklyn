class TrackingNumberNotification < Notification
  attr_accessor :order, :listing, :shipment

  def complete?
    ! (order.nil? || listing.nil? || shipment.nil?)
  end
end
