require 'brooklyn/sprayer'
require 'ladon'

module PaypalPayments
  class AfterCreationJob < Ladon::Job
    include Brooklyn::Sprayer

    @queue = :payments

    def self.work(id)
      with_error_handling("After creation of PayPal payment #{id}") do
        payment = PaypalPayment.find(id)
        send_created_email(payment)
      end
    end

    def self.send_created_email(payment)
      send_email(:created, payment)
    end
  end
end
