# Models a payment from the Copious marketplace bank account to a bank deposit account.
#
# Balanced uses next-day ACH to pay these payments.
class BankPayment < SellerPayment
  class SyncStateError < Exception; end

  # Syncs the payment's state with that of the backing Balanced credit transaction. Assumes this payment is pending and,
  # if the credit is cleared or rejected, updates the payment's state.
  #
  # @raise [BankPayment::SyncStateError] if the state check fails for some reason
  def sync_state!
    logger.debug("Syncing credit state of bank payment #{id}")
    credit = order.credit or
      raise SyncStateError.new("No credit for bank payment #{id}")
    credit_state = order.credit.state.present? && order.credit.state.to_sym or
      raise SyncStateError.new("Blank credit state for bank payment #{id}")
    case credit_state
    when :pending
      # no change to make
    when :cleared
      logger.debug("Marking bank payment #{id} paid")
      pay!
    when :rejected
      logger.debug("Marking bank payment #{id} rejected")
      reject!
    when :canceled
      logger.debug("Marking bank payment #{id} canceled")
      cancel!
    else
      raise SyncStateError.new("Unknown credit state #{credit_state} for bank payment #{id}")
    end
  end

  # Returns all payments whose states need to be synced. Currently this is all pending payments. May be enhanced in
  # the future to introduce a delay between each sync for a particular payment.
  #
  # @return [ActiveRecord::Relation]
  def self.find_all_to_sync_state
    # eager fetch order since it's needed in order to sync state
    with_state(:pending).includes(:order)
  end

  # Yields each payment whose state needs to be synced.
  #
  # @yieldparam [BankPayment] payment
  # @see #find_all_to_sync_state
  def self.find_each_to_sync_state(&block)
    find_all_to_sync_state.find_each(&block)
  end
end
