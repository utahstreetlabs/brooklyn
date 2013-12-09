require 'ladon'

module BankPayments
  # Checks the Balanced transactions underlying pending bank payments to see if their states have changed.
  class SyncStateJob < Ladon::Job
    @queue = :payments

    def self.work
      BankPayment.find_each_to_sync_state do |payment|
        with_error_handling("Syncing state for bank payment #{payment.id}", payment_id: payment.id) do
          payment.sync_state!
        end
      end
    end
  end
end
