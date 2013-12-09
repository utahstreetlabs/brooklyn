require 'datagrid'
require 'anchor/models/offer'
require 'brooklyn/sprayer'

# XXX: Move credit triggers back into mysql and use STI to replace credit type codes with subclasses of Credit.
class Credit < ActiveRecord::Base
  include Brooklyn::Sprayer

  class MinimumRealChargeRequired < Exception; end
  class NotEnoughCreditAvailable < Exception; end
  class IneligibleForCredit < Exception; end
  class InvalidUserState < IneligibleForCredit; end
  class InviteNotFound < IneligibleForCredit; end
  class InviterNotRegistered < IneligibleForCredit; end
  class InvalidUserConnectivity < IneligibleForCredit; end
  class InviteCapped < IneligibleForCredit; end

  belongs_to :user
  belongs_to :offer
  has_many :debits, dependent: :destroy
  scope :expired, -> { where('expires_at <= ?', Time.zone.now) }
  scope :unexpired, -> { where('(expires_at IS NULL) OR (expires_at > ?)', Time.zone.now)}

  validates :amount, presence: true, numericality: {greater_than: 0}
  validates :amount_used, presence: true, numericality: {greater_than_or_equal_to: 0}

  attr_accessible :amount, :expires_at

  def self.config
    Brooklyn::Application.config.credits
  end

  def expired?
    expires_at and (expires_at < Time.now)
  end

  def used?
    amount_used >= amount
  end

  def unused?
    not used?
  end

  def amount_used(options = {})
    scope = self.debits
    scope = scope.joins(:order).where(['listing_id <> ?', options[:listing].id]) if options.key?(:listing)
    scope.sum(:amount)
  end

  def amount_remaining(options = {})
    amount - amount_used(options)
  end

  def amount_available(options = {})
    expired? ? 0.00 : amount_remaining(options)
  end

  # Attempts to apply +total+ from this credit to +order+ and returns the portion of +total+ that could not be applied.
  # As a side effect, saves a debit for the amount of credit successfully applied.
  #
  # @param [BigDecimal] +total+ the amount of credit to apply to +order+
  # @param [Order] +order+ the order to apply credit to
  # @return [BigDecimal] anywhere from 0.00 to +total+
  def consume(total, order)
    consumed = [total, amount_remaining].min
    debit = debits.build({amount: consumed})
    debit.order = order
    consumed = 0 unless debit.save
    total - consumed
  end

  def validity_duration
    expires_at - created_at
  end

  def time_remaining
    expires_at - Time.now
  end

  def minimum_purchase
    self.offer ? self.offer.minimum_purchase : 0.00
  end

  def create_trigger(type, attrs={})
    trigger = Lagunitas::CreditTrigger.create(type, self.user_id, self.id, attrs)
    if trigger
      self.trigger_id = trigger.id
      self.save!
      trigger
    end
  end

  def trigger
    @trigger = Lagunitas::CreditTrigger.get_for_credit(self.id) unless defined?(@trigger)
  end

  after_commit on: :create do
    Credits::AfterCreatedJob.enqueue(self.id)
  end

  def self.unused(user, options = {})
    debit_table = Debit.quoted_table_name
    scope = where(user_id: user.id)
    if listing = options[:listing]
      order_table = Order.quoted_table_name
      join_table = "(#{debit_table} JOIN #{order_table} ON #{debit_table}.order_id = #{order_table}.id AND #{order_table}.listing_id != #{listing.id})"
      scope = scope.where(['offer_id IS NULL OR offer_id IN (?)', Offer.valid_for_listing(listing).map(&:id)])
    else
      join_table = debit_table
    end
    scope.all(
      joins: "LEFT JOIN #{join_table} ON #{debit_table}.credit_id = #{quoted_table_name}.id",
      select: "#{quoted_table_name}.*, SUM(COALESCE(#{debit_table}.amount, 0)) AS used",
      group: "#{quoted_table_name}.id",
      having: "used < #{quoted_table_name}.amount")
  end

  def self.available(user, options = {})
    unexpired.unused(user, options)
  end

  def self.available_by_expiration_time(user, options = {})
    # in order to get non-expiring credits to the end, and a deterministic sort,
    # use a quintuple sort key that orders by:
    #   * association with a specific seller
    #   * whether there is an offer associated with the credit, and of those, take ones with a minimum price first
    #   * presence of an expiry time
    #   * actual expiry time
    #   * creation time
    available(user, options).sort_by do |c|
      offer = c.offer_id ? Offer.find(c.offer_id) : nil
      # we don't check any match conditions on the offer, because +available+ did that.
      # so checking if conditions exist is enough here.
      [((offer && offer.sellers.any?) ? 0 : 1), (offer ? -offer.minimum_purchase : 1),
       (c.expires_at.nil?? 1 : 0), c.expires_at.to_i, c.created_at.to_i]
    end
  end

  # Attempts to apply +amount+ of the buyer's credits to +order+. Clears the existing debits and then consumes credits
  # in order of expiration time until +amount+ is covered. If the buyer does not have enough credits to cover the total
  # amount, no credit is applied and the existing debits are preserved.
  #
  # @param [BigDecimal] +amount+ the amount of credit to apply to +order+
  # @param [Order] +order+ the order to apply credit to
  # @raise [Credit::NotEnoughCreditAvailable] if the buyer does not have enough credit
  def self.consume!(amount, order)
    remainder = amount.to_d
    self.transaction do
      # when debits are created through the +Credit+ instance, the order doesn't know to delete them unless we
      # explicitly force reload, hence +debits(true)+
      order.debits(true).delete_all

      self.available_by_expiration_time(order.buyer, listing: order.listing).each do |credit|
        remainder = credit.consume(remainder, order)
        break unless remainder > 0
      end

      # roll back the tx so no credit is applied if the entire amount could not be consumed
      raise NotEnoughCreditAvailable unless remainder == 0
    end
  end

  # Raises an exception if applying +amount+ of the buyer's credit to +order would cause the buyer to not pay at least
  # he minimum real charge required for an order.
  #
  # @param [BigDecimal] +amount+ the amount of credit to potentially apply to +order+
  # @param [Order] +order+ the order to potentially apply credit to
  # @raise [Credit::MinimumRealChargeRequired] if the buyer would not end up paying the minimum real charge
  def self.assert_buyer_pays_minimum_real_charge!(amount, order)
    (order.listing.total_price - amount >= Credit.minimum_real_charge) or raise MinimumRealChargeRequired
  end

  def self.grant!(user, type, trigger_attrs = {})
    config = Brooklyn::Application.config.credits.send(type)
    credit = new(amount: config.amount, expires_at: Time.now + config.duration)
    credit.user = user
    transaction do
      credit.save!
      # it's certainly possible that the invite could have been capped since we checked eligibility. we're okay with
      # granting a few extra credits, and there's not an easy way to fix the race condition.
      user.credit_invite_acceptance! if type == :invitee && user.accepted_invite?
    end
    trigger = credit.create_trigger(type.to_s.classify, trigger_attrs)
    Credits::AfterTriggerCreatedJob.enqueue(credit.id) if trigger
    credit
  end

  # Returns true if +user+ is eligible for a credit of +type+.
  #
  # For all types, the user must be in the connected or registered states.
  #
  # For +:invitee+ credits, the following must also be true:
  #   1. The user must have accepted an invite,
  #   2. the inviter must be in the registered state,
  #   3. the inviter must not be capped for credited acceptances, and
  #   4. the user must have at least +Credit.min_invitee_followers+ social connections.
  #
  # For +:inviter+ credits, the following must also be true:
  #   1. The user must not be capped for credited acceptances.
  #   2. the invitee must have at least +Credit.min_invitee_followers+ social connections.
  def self.eligibility(user, type, options = {})
    raise InvalidUserState unless user.connected? || user.registered?
    case type
    when :invitee
      raise InviteNotFound unless user.accepted_invite?
      inviter = user.accepted_inviter
      raise InviterNotRegistered unless inviter && inviter.registered?
      if inviter.credited_invite_acceptance_capped?
        user.add_top_message(InviteeInviteCappedTopMessage.new(user, inviter))
        raise InviteCapped
      end
      unless user.person.minimally_connected?(Credit.min_invitee_followers)
        user.add_top_message(TopMessage.new(:invalid_user_connectivity))
        raise InvalidUserConnectivity
      end
    when :inviter
      raise InviteCapped if user.credited_invite_acceptance_capped?
      if options[:invitee_id]
        invitee = User.find_by_id(options[:invitee_id])
        raise InvalidUserConnectivity if invitee && !invitee.person.minimally_connected?(Credit.min_invitee_followers)
      end
    end
    true
  end

  def self.grant_if_eligible!(user, type, attrs = {})
    begin
      grant!(user, type, attrs) if self.eligibility(user, type, attrs)
    rescue IneligibleForCredit => e
      logger.warn("Not granting #{type} credit with attrs #{attrs} to ineligible user #{user.id} (#{e.class})")
      false
    end
  end

  # Returns a user's inviter credits as a hash of invitee id to credit.
  def self.inviter_credits_for_user(user_id)
    triggers = Lagunitas::CreditTrigger.find_for_user(user_id).find_all { |t| t.is_a?(Lagunitas::InviterCreditTrigger) }
    if triggers.any?
      idx = triggers.each_with_object({}) { |t, m| m[t.credit_id] = t }
      where(id: triggers.map(&:credit_id)).each_with_object({}) { |c, m| m[idx[c.id].invitee_id] = c }
    else
      []
    end
  end

  def self.min_days_halfway_reminder
    config.min_days_halfway_reminder
  end

  def self.max_inviter_credits_per_invitee
    config.inviter.max_per_invitee
  end

  def self.min_invitee_followers
    config.invitee.min_followers
  end

  def self.amount_for_accepted_invite
    config.inviter.amount
  end

  # Returns the credit amount a user stands to gain given a number of invitations he has sent.
  def self.amount_for_accepted_invites(invite_count)
    total_possible = invite_count * amount_for_accepted_invite
    [total_possible, max_inviter_credits_per_invitee].min
  end

  def self.invitee_credit_amount
    config.invitee.amount
  end

  # The minimum amount that the buyer must spend to buy an item - credits may not be used to cover this amount.
  def self.minimum_real_charge
    config.minimum_real_charge
  end

  # Whether or not to suggest that the user apply the maximum applicable credit to an order.
  def self.apply_suggest_max_applicable?
    !!config.apply.suggest_max_applicable
  end

  # The number of times to retry the application of credit to an order payment before giving up for good.
  def self.apply_retries
    config.apply.retries
  end

  # The number of seconds after which a credit expires, if not otherwise specified.
  def self.default_duration
    config.default.duration
  end
end
