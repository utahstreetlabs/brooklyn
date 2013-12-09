require 'balanced'

module Orders
  class PaymentDeclined < Exception; end
  class InvalidPaymentState < Exception; end

  module Balanced
    extend ActiveSupport::Concern
    include ActiveSupport::Benchmarkable

    included do
      attr_accessor :purchase, :skip_debit, :skip_credit, :skip_refund
      attr_accessible :balanced_debit_url, :balanced_credit_url, :balanced_refund_url
    end

    # Processes the buyer's payment. Requires that the +purchase+ attribute has been set. Creates a Balanced credit
    # card and adds it to the user's Balanced account (creating one if necessary). As a side effect, saves this
    # record's +billing_address+ and +balanced_debit_url+.
    #
    # @raise [Orders::InvalidPaymentState] if the buyer has already been debited
    # @raise [Purchase::CardRejected] if the card could not be tokenized
    # @raise [Purchase::CardNotValidated] if the card could not be validated
    # @raise [Orders::PaymentDeclined] if the payment was declined
    # @raise [Balanced::Error] if the payment could not be processed for some other reason
    # @see +Purchase.create_card!
    # @see +Users::Balanced.create_buyer!
    # @see https://www.balancedpayments.com/docs/api/#debits
    def process_purchase!
      raise InvalidPaymentState.new("Already debited") if debited? && !skip_debit
      raise ArgumentError.new("No purchase") unless purchase
      billing_address = PostalAddress.new_billing_address(purchase.to_billing_address_attrs)
      billing_address.user = buyer
      # until we store credit card numbers with their billing addresses locally, there's no real reason for the
      # user to have to pick a unique name for a billing address, so we just use the order number.
      billing_address.name = reference_number
      self.billing_address = billing_address
      unless skip_debit
        card = purchase.create_card!
        buyer_account = buyer.create_buyer!(card)
        cents = ((listing.subtotal + buyer_fee) * 100).to_i
        begin
          d = benchmark "Debit buyer #{buyer.id} of order #{id} #{cents} cents from card #{card.uri}" do
            buyer_account.debit(cents, nil, nil, {}, balanced_tx_description, card.uri)
          end
          self.balanced_debit_url = d.uri
        rescue ::Balanced::PaymentRequired => e
          logger.warn("Payment for order #{id} declined: #{e.message}")
          raise PaymentDeclined.new(e.message)
        end
      end
      save!(validate: false)
    end

    # Transfers the seller's proceeds from the marketplace account to the given deposit account. As a side effect,
    # saves this record's +balanced_credit_url+.
    #
    # @param [DepositAccount] deposit_account the account to which the proceeds will be deposited
    # @raise [Orders::InvalidPaymentState] if the seller has already been credited or if the buyer was never debited
    #   in the first place
    # @raise [Balanced::Error] if the credit could not be processed for some other reason
    # @see https://www.balancedpayments.com/docs/api#credit
    def pay_seller!(deposit_account)
      return if skip_credit
      raise ArgumentError.new("Deposit account must not be nil") if deposit_account.nil?
      raise InvalidPaymentState.new("Already credited") if credited?
      raise InvalidPaymentState.new("Not yet debited") unless debited?
      amount = listing.proceeds
      cents = (amount * 100).to_i
      c = benchmark ("Credit seller %d of order %d %d cents to account %s" %
                     [listing.seller.id, id, cents, deposit_account.balanced_url]) do
        listing.seller.balanced_account.credit(cents, balanced_tx_description, {}, deposit_account.balanced_url)
      end
      self.balanced_credit_url = c.uri
      p = if deposit_account.is_a?(PaypalAccount)
        self.build_paypal_payment(amount: amount)
      else
        self.build_bank_payment(amount: amount)
      end
      p.deposit_account = deposit_account
      save!(validate: false)
    end

    # Issues a full refund to the buyer's payment source from the marketplace account. As a side effect, saves this
    # record's +balanced_refund_url+.
    #
    # @raise [Orders::InvalidPaymentState] if the buyer has already been refunded or was never debited in the first
    #   place
    # @raise [Balanced::Error] if the refund could not be issued for some other reason
    # @see https://www.balancedpayments.com/docs/api#refunds
    def refund_buyer!
      return if skip_refund
      raise InvalidPaymentState.new("Already refunded") if refunded?
      raise InvalidPaymentState.new("Not yet debited") unless debited?
      d = self.debit
      begin
        r = benchmark "Issue refund to buyer #{buyer.id} of order #{id}" do
          d.refund(nil, balanced_tx_description)
        end
      rescue ::Balanced::BadRequest => e
        # 400/invalid-amount means that the debit was already refunded. see
        # https://utahstreetlabs.lighthouseapp.com/projects/87974/tickets/408
        # if we got this far and discovered a refund, it means that the refund was issued on the Balanced side, and
        # we need to update the order to reflect the refund.
        raise e unless e.category_code == 'invalid-amount'
        logger.warn("Could not issue refund to buyer #{buyer_id} of order #{id}: debit refunded out of band")
        r = benchmark "Find refund of debit #{balanced_debit_url} for buyer #{buyer.id} of order #{id}" do
          d.refunds.first
        end
      end
      self.balanced_refund_url = r.uri
      save!(validate: false)
    end

    def debited?
      balanced_debit_url.present?
    end

    def debit
      unless instance_variable_defined?(:@balanced_debit)
        return nil unless balanced_debit_url
        @balanced_debit = benchmark "Find debit for order #{id} at #{balanced_debit_url}" do
          ::Balanced::Debit.find(balanced_debit_url)
        end
      end
      @balanced_debit
    end

    def credited?
      balanced_credit_url.present?
    end

    def credit
      unless instance_variable_defined?(:@balanced_credit)
        return nil unless balanced_credit_url
        @balanced_credit = benchmark "Find credit for order #{id} at #{balanced_credit_url}" do
          ::Balanced::Credit.find(balanced_credit_url)
        end
      end
      @balanced_credit
    end

    def refunded?
      balanced_refund_url.present?
    end

    def refund
      unless instance_variable_defined?(:@balanced_refund)
        return nil unless balanced_refund_url
        @balanced_refund = benchmark "Find refund for order #{id} at #{balanced_refund_url}" do
          ::Balanced::Refund.find(balanced_refund_url)
        end
      end
      @balanced_refund
    end

    def seller_has_merchant_account?
      listing.seller.balanced_merchant?
    end

    def balanced_tx_description
      I18n.t('models.order.balanced_tx_description', reference_number: reference_number, listing_title: listing.title)
    end
  end
end
