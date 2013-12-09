class TransactionHistory
  include Enumerable
  include Ladon::Logging

  attr_reader :viewer, :transactions, :records
  delegate :each, to: :records

  def initialize(viewer, transactions)
    @viewer = viewer
    @transactions = transactions
    @records = transactions.map { |tx| Record.new(viewer, tx) }
    eager_fetch_paypal_payments
  end

  def eager_fetch_paypal_payments
    if records.any?
      urls = records.find_all { |r| r.credited_to_paypal? }.map(&:url)
      if urls.any?
        payments = PaypalPayment.find_all_by_balanced_credit_url(urls).group_by { |p| p.balanced_credit_url }
        records.each do |record|
          record.paypal_payment = payments[record.url].first if payments[record.url]
        end
      end
    end
  end

  class Record
    include Ladon::Logging

    attr_reader :viewer, :tx, :created_at, :amount, :type
    attr_accessor :paypal_payment
    delegate :description, :destination, :state, to: :tx

    def initialize(viewer, tx)
      @viewer = viewer
      @tx = tx
      @created_at = Time.zone.parse(tx.created_at)
      @amount = tx.amount/100.to_f
      @type = tx.class.name.demodulize.underscore.to_sym
    end

    def credit?
      @credit ||= tx.is_a?(Balanced::Credit)
    end

    def debit?
      @debit ||= tx.is_a?(Balanced::Debit)
    end

    def refund?
      @refund ||= tx.is_a?(Balanced::Refund)
    end

    def account
      unless instance_variable_defined?(:@account)
        @account = if credit?
          tx.destination
        elsif debit?
          tx.source
        elsif refund?
          tx.debit.source
        end
      end
      @account
    end

    def card_account?
      @card_account ||= account && account.is_a?(Balanced::Card)
    end

    def bank_account?
      @bank_account ||= account && account.is_a?(Balanced::BankAccount)
    end

    def url
      tx.uri
    end

    def account_url
      account && account.uri
    end

    def credited_to_paypal?
      @credited_to_paypal ||= credit? && bank_account? && DepositAccount.marketplace_bank_account?(account)
    end

    def deposit_account
      unless instance_variable_defined?(:@deposit_account)
        # don't use User.deposit_account_backed_by because that issues a separate LIMIT 1 query for each record in the
        # tx history, whereas User.deposit_accounts is cached after the first query
        @deposit_account = credit? && bank_account? &&
          viewer.deposit_accounts.detect { |da| da.balanced_url == account_url }
      end
      @deposit_account
    end
  end
end
