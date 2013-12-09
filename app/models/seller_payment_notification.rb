class SellerPaymentNotification < Notification
  attr_accessor :seller_payment, :order, :listing

  def complete?
    ! (seller_payment.nil? || order.nil? || listing.nil?)
  end
end
