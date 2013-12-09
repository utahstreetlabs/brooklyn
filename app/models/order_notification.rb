class OrderNotification < Notification
  attr_accessor :order, :listing, :buyer, :seller, :shipment

  def complete?
    ! (order.nil? || listing.nil? || buyer.nil? || seller.nil?)
  end
end
