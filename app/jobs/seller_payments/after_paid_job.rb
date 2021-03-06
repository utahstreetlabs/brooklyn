require 'brooklyn/sprayer'
require 'ladon'

module SellerPayments
  class AfterPaidJob < Ladon::Job
    include Brooklyn::Sprayer
    @queue = :payments

    def self.work(id)
      with_error_handling("After seller payment #{id} paid") do
        payment = SellerPayment.find(id)
        notify_seller(payment)
        email_seller(payment) if payment.is_a?(BankPayment)
      end
    end

    def self.notify_seller(payment)
      inject_notification(:SellerPaymentPaid, payment.order.listing.seller_id, payment_id: payment.id)
    end

    def self.email_seller(payment)
      send_email(:paid_for_seller, payment)
    end
  end
end
