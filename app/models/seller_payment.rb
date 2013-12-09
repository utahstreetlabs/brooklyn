require 'state_machine'

# Models a payment from the Copious marketplace bank account to a seller's deposit account.
class SellerPayment < ActiveRecord::Base
  include Brooklyn::Sprayer

  belongs_to :order
  belongs_to :deposit_account

  attr_accessible :amount

  state_machine :state, initial: :pending do
    before_transition on: :pay do |payment|
      payment.paid_at = Time.zone.now
    end
    event :pay do
      transition pending: :paid
    end
    after_transition on: :pay do |payment|
      SellerPayments::AfterPaidJob.enqueue(payment.id)
    end

    before_transition on: :reject do |payment|
      payment.rejected_at = Time.zone.now
    end
    event :reject do
      transition pending: :rejected
    end
    after_transition on: :reject do |payment|
      SellerPayments::AfterRejectedJob.enqueue(payment.id)
    end

    before_transition on: :cancel do |payment|
      payment.canceled_at = Time.zone.now
    end
    event :cancel do
      transition pending: :canceled
    end
  end

  # Returns those payments for the orders with the provided Balanced credit URLs. Each payment returned by this finder
  # includes a +balanced_credit_url+ attribute.
  #
  # @return [ActiveRecord::Relation]
  def self.find_all_by_balanced_credit_url(urls)
    select("#{quoted_table_name}.*, #{Order.quoted_table_name}.balanced_credit_url").
      joins(:order).where(orders: {balanced_credit_url: urls})
  end
end
