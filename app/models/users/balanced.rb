require 'balanced'

module Users
  # Gives a user access to an account in the Balanced payment system. This account can have both _buyer_ and _merchant_
  # roles. A merchant account is associated with bank accounts to which payments can be credited for completed orders.
  # A buyer account is associated with credit card accounts from which payments can be debited when placing orders.
  #
  # @see DepositAccount
  # @see Balanced
  module Balanced
    extend ActiveSupport::Concern
    include ActiveSupport::Benchmarkable

    included do
      has_many :deposit_accounts, dependent: :destroy
      has_one :default_deposit_account, class_name: 'DepositAccount', conditions: {default: true}
    end

    # Returns the user's Balanced account, if any.
    #
    # @return [Balanced::Account]
    def balanced_account
      unless defined?(@balanced_account)
        return nil unless balanced_url
        begin
          @balanced_account = benchmark "Find Balanced account for user #{id}" do
            ::Balanced::Account.find(balanced_url)
          end
        rescue ::Balanced::Error => e
          logger.error("BALANCED: Error finding Balanced account for user #{id}: #{e.message}")
          nil
        rescue Faraday::Error::TimeoutError => e
          logger.warn("BALANCED: Timeout finding Balanced account for user #{id}: #{e.message}")
          nil
        end
      end
      @balanced_account
    end

    # Returns whether or not the user has a Balanced account.
    #
    # @return [Boolean]
    def balanced_account?
      !!balanced_account
    end

    # Returns whether or not the user has a Balanced account with the +merchant+ role.
    #
    # @return [Boolean]
    def balanced_merchant?
      balanced_account? && balanced_account.roles.include?('merchant')
    end

    # Returns whether or not the user has a Balanced account with the +buyer+ role.
    #
    # @return [Boolean]
    def balanced_buyer?
      balanced_account? && balanced_account.roles.include?('buyer')
    end

    # Creates and returns a Balanced account with the _merchant_ role for this user. If the user already has a
    # Balanced account, adds the _merchant_ role to the account. As a side effect, saves this record's +balanced_url+.
    #
    # If the identity does not contain enough information for Balanced to validate, +Balanced::MoreInformationRequired+
    # will be raised. This generally means a tax id needs to be included (which is not required normally; for most
    # people, street address, postal code and phone number are good enough).
    #
    # @param [Balanced::PersonMerchantIdentity] the identity information required to validate and create the merchant
    #   account
    # @return [Balanced::Account] the newly-created merchant account
    # @raise [Balanced::MoreInformationRequired] if the identity information cannot be validated
    # @raise [Balanced::Error] if the merchant account cannot be created for some other reason
    # @see https://www.balancedpayments.com/docs/api/#accounts
    def create_merchant!(identity)
      return balanced_account if balanced_merchant?
      merchant_params = identity.to_merchant_params
      if balanced_account
        benchmark "Promote Balanced account to merchant for user #{id}" do
          @balanced_account = balanced_account.promote_to_merchant(merchant_params)
        end
      else
        begin
          @balanced_account = benchmark "Create Balanced merchant account for user #{id}" do
            marketplace.create_merchant(email, merchant_params, nil, name)
          end
          # XXX: remove after fixing https://www.pivotaltracker.com/story/show/34912233
#          logger.debug("Created Balanced merchant account #{balanced_account.inspect} for user #{id}")
          self.balanced_url = balanced_account.uri
        rescue ::Balanced::Conflict => e
          # this should only ever happen when different development environments use the same test marketplace and
          # have their own users with the same email address (eg I have bcm@maz.org users on three different
          # development machines all sharing the same test marketplace).
          logger.warn("User #{id} has Balanced account (email #{email}) but URL is not saved")
          self.balanced_url = e.extras[:account_uri]
          benchmark "Promote Balanced account to merchant for user #{id}" do
            @balanced_account = balanced_account.promote_to_merchant(merchant_params)
          end
        end
        # XXX: remove after fixing https://www.pivotaltracker.com/story/show/34912233
#        logger.debug("Saving changes #{changes.inspect} for user #{id}")
        save!(validate: false)
      end
      balanced_account
    end

    # Creates and returns a Balanced account with the _buyer_ role for this user and associates +card+ with the
    # account. If the user already has a Balanced account, adds the _buyer_ role to the account. As a side effect,
    # saves this record's +balanced+url+.
    #
    # @return [Balanced::Account] the newly-created buyer account
    # @raise [Balanced::Error] if the buyer account could not be created for some reason
    # @see https://www.balancedpayments.com/docs/api/#accounts
    def create_buyer!(card)
      if balanced_account
        benchmark "Add card to Balanced buyer account for user #{id}" do
          @balanced_account = balanced_account.add_card(card.uri) # adds buyer role to account if necessary
        end
      else
        begin
          benchmark "Create Balanced buyer account for user #{id}" do
            @balanced_account = marketplace.create_buyer(email, card.uri) # adds card
          end
          self.balanced_url = balanced_account.uri
        rescue ::Balanced::Conflict => e
          # this should only ever happen when different development environments use the same test marketplace and
          # have their own users with the same email address (eg I have bcm@maz.org users on three different
          # development machines all sharing the same test marketplace).
          logger.warn("User #{id} has Balanced account (email #{email}) but URL is not saved")
          self.balanced_url = e.extras[:account_uri]
          benchmark "Add card to Balanced buyer account for user #{id}" do
            @balanced_account = balanced_account.add_card(card.uri) # adds buyer role to account if necessary
          end
        end
        save!(validate: false)
      end
      balanced_account
    end

    # Returns a subset of the user's Balanced transaction history in reverse chronological order.
    #
    # @option options [Integer] :page (1)
    # @option options [Integer] :per (10) max 100
    # @return [Balanced::Pager]
    # @raise [Balanced::Error]
    def balanced_transactions(options = {})
      options = options.reverse_merge(sort: 'created_at,desc')
      # XXX: filter out holds on the server side
      benchmark "Find Balanced transactions for user #{id} with options #{options}" do
        pager = ::Balanced::Pager.new(balanced_account.transactions_uri, options)
        pager.offset # forces the query so that the timing statement is correct
        pager
      end
    end

    # Returns the user's deposit account which is backed by +bank_account+, if any.
    #
    # @param [Balanced::BankAccount] bank_account
    # @return [DepositAccount] or +nil+
    def deposit_account_backed_by(bank_account)
      deposit_accounts.where(balanced_url: bank_account.uri).first
    end

    # Returns whether or not this user has a default deposit account.
    #
    # @return [Boolean]
    def default_deposit_account?
      !!default_deposit_account
    end

    # Returns whether or not this user's default deposit account is a PayPal account.
    #
    # @return [Boolean]
    def default_deposit_to_paypal?
      default_deposit_account.is_a?(PaypalAccount)
    end

    def marketplace
      ::Balanced::Marketplace.my_marketplace
    end
  end
end
