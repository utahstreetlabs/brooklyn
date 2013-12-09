require 'balanced'

# A financial account to which a seller deposits funds from completed orders.
class DepositAccount < ActiveRecord::Base
  include ActiveSupport::Benchmarkable

  belongs_to :user

  attr_accessor :skip_create, :skip_invalidate
  attr_accessible :default, :balanced_url
  validates :default, inclusion: {in: [true, false]}

  BANK = :bank
  PAYPAL = :paypal

  # Returns the Balanced bank account backing this account.
  #
  # @return [Balanced::BankAccount]
  def balanced_account
    unless defined?(@balanced_account)
      return nil unless balanced_url
      @balanced_account = benchmark "Find Balanced bank account for account #{id}" do
        Balanced::BankAccount.find(balanced_url)
      end
    end
    @balanced_account
  end

  def self.factory(type, attrs = {})
    case type.to_sym
    when BANK then BankAccount.new(attrs)
    when PAYPAL then PaypalAccount.new(attrs)
    else raise ArgumentError.new("Unknown payment account type #{type}")
    end
  end

  def self.marketplace_bank_account_params
    {
      name: current_marketplace_bank_account.name,
      account_number: current_marketplace_bank_account.number,
      bank_code: current_marketplace_bank_account.routing_number
    }
  end

  def self.marketplace_bank_accounts
    Brooklyn::Application.config.balanced.marketplace_bank_accounts
  end

  def self.current_marketplace_bank_account
    marketplace_bank_accounts.first
  end

  def self.marketplace_bank_account?(bank_account)
    marketplace_bank_accounts.any? do |ba|
      bank_account.bank_code == ba.routing_number && bank_account.last_four == ba.last_four
    end
  end

  class UnidentifiedBank < Exception; end

  protected
    def remove_other_defaults
      user.deposit_accounts.update_all(default: false) if default_changed? && default?
    end
    before_save :remove_other_defaults

    # Creates and returns a Balanced bank account associated with the user's merchant account. As a side effect, sets
    # the record's +balanced_url+ and +last_four+ attributes. Note that this method does not save the record, as it's
    # meant only to be called as a callback.
    #
    # @return [Balanced::BankAccount]
    # @raise [UnidentifiedBank] if the provided routing number can't be matched to an actual bank
    def create_balanced_account!
      return if skip_create
      ba = begin
        benchmark "Create Balanced bank account for user #{user.id}" do
          new_balanced_account.save
        end
      rescue Balanced::BadRequest => e
        # 400/invalid-routing-number means that the routing number can't be matched to an actual bank
        # see https://utahstreetlabs.lighthouseapp.com/projects/87974-copious/tickets/406
        if e.category_code == 'invalid-routing-number'
          raise UnidentifiedBank.new
        else
          raise e
        end
      end
      benchmark "Add Balanced bank account to merchant account for user #{user.id}" do
        user.balanced_account.add_bank_account(ba.uri)
      end
      self.balanced_url = ba.uri
      # adding the bank account to the user's account changes the bank account's uri. we need to fetch the bank
      # account from Balanced again to get the new url.
      self.balanced_url = balanced_account.uri
      self.last_four = balanced_account.last_four
      balanced_account
    end
    before_create :create_balanced_account!

    def new_balanced_account
      Balanced::BankAccount.new(to_balanced_params)
    end

    # Marks the associated Balanced bank account invalid so that it can no longer be credited. It can still be
    # retrieved via +#balanced_account+ even when not valid.
    def invalidate_balanced_account!
      return if skip_invalidate
      benchmark "Invalidate Balanced bank account for account #{id}" do
        balanced_account.is_valid = false
        @balanced_account = balanced_account.save
      end
    end
    before_destroy :invalidate_balanced_account!
end
