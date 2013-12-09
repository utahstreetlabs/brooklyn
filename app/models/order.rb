require 'active_shipping'
require 'brooklyn/sprayer'
require 'brooklyn/usage_tracker'
require 'datagrid'
require 'ladon/error_handling'
require 'state_machine'

class Order < ActiveRecord::Base
  include ApiAccessable
  include Brooklyn::UniqueIndexEnforceable
  include Brooklyn::Sprayer
  include Ladon::ErrorHandling
  include OrderDatagrid
  include Orders::Api
  include Orders::PrepaidShipping
  include Orders::Balanced

  module FailureReasons
    NEVER_SHIPPED = :never_shipped
    ALL = [NEVER_SHIPPED]
  end

  belongs_to :buyer, :class_name => 'User'

  # XXX: revisit these destroy conditions when we can deactivate users
  has_one :shipment, dependent: :destroy, autosave: true
  has_one :return_shipment, class_name: 'Shipment', dependent: :destroy, autosave: true, conditions: { :return => true }
  has_one :buyer_rating, dependent: :destroy
  has_one :seller_rating, dependent: :destroy
  has_many :debits, dependent: :destroy
  belongs_to :listing
  has_one :shipping_address, class_name: 'PostalAddress', conditions: {ref_type: PostalAddress::RefType::SHIPPING},
          dependent: :nullify
  has_one :billing_address, class_name: 'PostalAddress', conditions: {ref_type: PostalAddress::RefType::BILLING},
          dependent: :nullify
  has_one :shipping_label, dependent: :nullify
  # In addition to seller_payment, we need the redundant payment associations in order to build the payment with
  # the correct type. reading should generally be done using seller_payment.
  # Note that if the order was settled before BankPayment was added to the model, the order will not have a seller
  # payment record at all. We may backfill these eventually, but since we only use these for post-settlement
  # payment status changes, we decided not to worry about it for now.
  has_one :seller_payment, dependent: :destroy
  has_one :bank_payment, class_name: 'BankPayment'
  has_one :paypal_payment, class_name: 'PaypalPayment'

  attr_accessible :buyer, :listing, :private
  attr_accessor :failure_reason

  has_uuid

  has_many :annotations, as: :annotatable, dependent: :destroy

  state_machine :status, :initial => :pending do
    # pending:               the order has been locked to a buyer
    # confirmed:             the payment has been authorized and the funds have been transferred from the buyer to
    #                        the marketplace account; the "handling period" begins now
    # shipped:               the item is in transit to the buyer
    # delivered:             the shipping service confirmed delivery of the item to the buyer
    # canceled:              the order was canceled prior to completion; the funds have been refunded to the buyer
    # complete:              either the buyer explicitly confirmed receipt, or the review window expired - either way
    #                        the transaction is complete from the perspective of the buyer, but the funds have not yet
    #                        been released to the seller
    # settled:               the funds have been released from the marketplace account to the seller
    # return_pending:        the buyer reported an issue and plans to return the item
    # return_shipped:        the returned item is in transit to the seller
    # return_delivered:      the shipping service confirmed delivery of the returned item to the seller
    # return_completed:      the seller confirmed receipt of the returned item; the funds have been refunded to the
    #                        buyer

    before_transition :on => :confirm do |order|
      order.process_purchase!
      Listing.transaction do
        order.listing.reload(lock: true)
        order.listing.sell! unless order.listing.sold?
      end
      order.confirmed_at = Time.zone.now
    end
    event :confirm do
      transition :pending => :confirmed
    end
    after_transition :on => :confirm do |order|
      Orders::AfterConfirmationJob.enqueue(order.id)
    end

    before_transition on: :ship do |order|
      order.shipped_at = Time.zone.now
    end
    event :ship do
      transition :confirmed => :shipped
    end
    state :shipped do
      validates :shipment, presence: true
    end
    after_transition :on => :ship do |order|
      if order.expired_shipping_label?
        order.logger.warn("Marking order #{order.id} shipped with shipping label #{order.shipping_label} that " +
          "expired at #{order.shipping_label.expired_at}")
      end
      Orders::AfterShipmentJob.enqueue(order.id)
    end

    before_transition :on => :deliver do |order|
      order.delivered_at = Time.zone.now
    end
    event :deliver do
      transition :shipped => :delivered
    end
    after_transition :on => :deliver do |order|
      Orders::AfterDeliveryJob.enqueue(order.id)
    end

    before_transition :on => :complete do |order|
      order.completed_at = Time.zone.now
      order.build_buyer_rating(user_id: order.buyer_id, purchased_at: order.confirmed_at, flag: true)
      order.build_seller_rating(user_id: order.listing.seller_id, purchased_at: order.confirmed_at, flag: true)
    end
    event :complete do
      transition :delivered => :complete
    end
    after_transition :on => :complete do |order|
      Orders::AfterCompletionJob.enqueue(order.id)
    end

    before_transition :on => :settle do |order|
      order.pay_seller!(order.listing.seller.default_deposit_account)
      order.settled_at = Time.zone.now
    end
    event :settle do
      transition :complete => :settled
    end

    before_transition :on => :cancel do |order|
      order.refund_buyer! if order.debited?
      order.canceled_at = Time.zone.now
    end
    event :cancel do
      transition [:pending, :confirmed, :shipped, :delivered] => :canceled
    end
    after_transition :on => :cancel do |order, transition|
      cancelled = CancelledOrder.create_from_order(order, previous_status: transition.from,
        failure_reason: order.failure_reason)
      # these actions have to happen while both the cancelled order and the original order exist, to prevent fk violations
      order.shipping_address.cancel_order! if order.shipping_address
      order.billing_address.cancel_order! if order.billing_address
      order.shipping_label.cancel_order! if order.shipping_label
      # there's no need to switch ratings from this order to the cancelled order, as an order in any of the states
      # that can transition to canceled should never have been rated
      order.destroy
      # no need for an after cancellation job, as those duties are performed by CancelledOrder's after creation job
    end

    event :return do
      transition :delivered => :return_pending
    end

    before_transition :on => :ship_return do |order|
      order.return_shipped_at = Time.zone.now
    end
    event :ship_return do
      transition :return_pending => :return_shipped
    end

    before_transition :on => :deliver_return do |order|
      order.return_delivered_at = Time.zone.now
    end
    event :deliver_return do
      transition :return_shipped => :return_delivered
    end

    before_transition :on => :complete_return do |order|
      order.return_completed_at = Time.zone.now
      # XXX: refund buyer's shipping cost
      # XXX: refund credit applied
    end
    event :complete_return do
      transition :return_delivered => :return_completed
    end
  end

  before_create do
    self.reference_number = self.class.generate_reference_number
  end

  after_destroy do
    # if something raises an exception during this callback, state_machine will attempt to roll back the order's state,
    # but since the order's attribute hash is frozen when it's destroyed, that will generate a runtime error trying to
    # update a frozen hash. therefore, we need to catch any possible exceptions and ensure that we handle them
    # appropriately.

    if listing.sold?
      self.class.with_error_handling("Relist listing after destroying order", listing_id: listing_id, order_id: id) do
        listing.relist!
      end
    end
  end

  after_commit on: :create do
    Orders::AfterCreationJob.enqueue(self.id)
  end

  after_commit do
    Orders::AfterFailureJob.enqueue(self.id) if failure_reason
  end

  class << self
    [
     # Once delivered, time after which order will be automatically completed
     :review_period_duration,
     # amount of time after handling period expires to cancel the order
     :confirmed_unshipped_cancellation_buffer,
     # Once shipped, time after which delivery confirmation period expires
     :delivery_confirmation_period_duration,
     # Once delivery confirmation requested, time after which admin followup is requested
     :delivery_non_confirmation_followup_period_duration,
     # amount of time after confirmation buyer can change shipping address
     :shipping_address_change_window,
     # remind seller of unshipped order this amount of time before the handling period ends
     :handling_period_full_reminder_window,
     # if the handling period is this or shorter, use the abbreviated reminder window instead
     :handling_period_reminder_abbrev_threshold,
     # if the handling period is abbreviated, remind seller of unshipped order this amount of time before the
     # handling period ends instead
     :handling_period_abbrev_reminder_window,
     # if the handling period is this or shorter, don't remind the seller of unshipped order at all
     :handling_period_reminder_none_threshold
    ].each do |meth|
      define_method(meth) do
        Brooklyn::Application.config.orders.send(meth)
      end
    end
  end

  scope :in_checkout, where(:status => [:pending])
  scope :in_fulfillment, where(:status => [:confirmed, :shipped, :delivered])
  scope :settled, where(status: :settled)
  scope :new_this_month, where('MONTH(confirmed_at) = MONTH(NOW())').where('YEAR(confirmed_at) = YEAR(NOW())')
  scope :new_today, new_this_month.where('DAY(confirmed_at) = DAY(NOW())')

  # Returns whether or not a given user is the buyer of this listing.
  def bought_by?(user)
    buyer_id == user.id
  end

  def shipped_at
    self.shipment.shipped_at if self.shipment
  end

  def shipped_at=(timestamp)
    self.shipment.shipped_at = timestamp if self.shipment
  end

  def delivered_at
    self.shipment.delivered_at if self.shipment
  end

  def delivered_at=(timestamp)
    self.shipment.delivered_at = timestamp if self.shipment
  end

  def tracking_number
    self.shipment.tracking_number if self.shipment
  end

  def shipping_carrier
    self.shipment.carrier if self.shipment
  end

  def shipping_carrier_key
    self.shipment.carrier.key if self.shipment && self.shipment.carrier
  end

  def shipping_carrier_name
    self.shipment.carrier.name if self.shipment && self.shipment.carrier
  end

  # Returns the time at which the transaction review period ends. Only valid when the order status is _delivered_.
  def review_period_ends_at
    raise "Not delivered" unless delivered?
    delivered_at + self.class.review_period_duration
  end

  def shipping_address_changeable?
    pending? or (confirmed? and (Time.zone.now < (confirmed_at + self.class.shipping_address_change_window)))
  end

  # Set the current shipping address for an order to the postal address with +address_or_id+
  # If a shipping address already exists for the order, deletes it.
  def copy_master_shipping_address!(address_or_id)
    new_address = address_or_id.is_a?(PostalAddress) ? address_or_id : buyer.postal_address(address_or_id)
    if new_address
      if not (self.shipping_address && self.shipping_address.equivalent?(new_address))
        transaction do
          self.shipping_address.destroy if self.shipping_address
          self.shipping_address = new_address.dup
        end
      end
    else
      logger.warn("No such postal address #{address_or_id} for buyer #{buyer_id}")
    end
  end

  def past_checkout?
    confirmed? || shipped? || delivered?
  end

  def can_track?
    (confirmed? && shipping_label && shipping_label.active?) || shipped? || delivered? || complete? || settled?
  end

  def finalized?
    settled? || canceled? || return_completed?
  end

  #XXX Fixed for now
  def discount
    0.00
  end

  def payment_type
    'Balanced' # XXX: use 'PoundPay' for legacy orders?
  end

  def credit_amount
    self.debits.sum(:amount) || 0
  end

  # Consume as many available credits as required to apply the desired $ amount to this order.
  #
  # If any credits have been previously applied to this order, those are unapplied and then a number of credits
  # sufficient to cover +amount+ are consumed from the resulting pool. An exception to this is when +amount+ is exactly
  # equal to the previously applied amount; in this case, the method does nothing.
  #
  # @param [Float] amount the total credit amount to be applied to this order, inclusive of any credits that have
  #   previously been applied
  # @raise if the order is in any state other than pending
  # @raise [Credit::MinimumRealChargeRequired] if the buyer would not wind up paying the minimum real charge amount
  # @raise [Credit::NotEnoughCreditAvailable] if the buyer's account does not have the required credit amount available
  # @see Credit#assert_buyer_pays_minimum_real_charge!
  # @see Credit#consume!
  def apply_credit_amount!(amount)
    raise 'Order must be pending to apply credit to it' unless pending?
    amount = amount.to_d # ensure big decimal, not floating point
    return if amount == credit_amount
    Credit.assert_buyer_pays_minimum_real_charge!(amount, self)
    Credit.consume!(amount, self)
  end

  # Returns the portion of a credit balance that may be applied to this order. The maximum value of the applicable
  # portion is the total price of the listing minus +Credit.minimum_real_charge+.
  #
  # @param [Float] balance the credit balance to be potentially applied to this order
  # @return [Float] the portion (or entirety) of the credit balance that is actually applicable to this order
  def applicable_credit(balance)
    balance = balance.to_d # ensure big decimal, not floating point
    listing.total_price > balance ? balance : listing.total_price - Credit.minimum_real_charge
  end

  # Cancels the order if it has not yet been confirmed.
  def cancel_if_unconfirmed!
    # perform inside a transaction to set an explicit scope for the lock we're taking
    transaction do
      reload(lock: true)
      cancel! if pending?
    end
  end

  # total price of this order taking into account any credit amount
  # that has been applied
  def total_price
    (listing.total_price - credit_amount).to_d
  end

  def credit_amount_lte_credit_balance?
    self.credit_amount <= self.buyer.credit_balance
  end

  def credit_amount_lte_total_listing_price?
    self.credit_amount <= self.listing.total_price
  end

  def buyer_fee
    (listing.buyer_fee - credit_amount).to_d
  end

  def credit_applied?
    credit_amount > 0
  end

  # Returns whether or not the order's delivery confirmation period has passed. Note that for orders that have been
  # delivered, this does not imply anything about whether the order was delivered within the confirmation period;
  # this method returns true for successfully completed orders whose confirmation period has passed just like it
  # does for non-delivered orders.
  #
  # @return [Boolean]
  def delivery_confirmation_elapsed?
    shipment && shipped_at && shipped_at < self.class.delivery_confirmation_period_duration.ago
  end

  def handling_duration
    listing.handling_duration
  end

  # Returns the number of seconds into the handling period after which a handling reminder should be sent. Returns
  # +nil+ if the handling period is not long enough to justify a reminder.
  def handling_reminder_after
    if handling_duration > self.class.handling_period_reminder_abbrev_threshold
      handling_duration - self.class.handling_period_full_reminder_window
    elsif handling_duration > self.class.handling_period_reminder_none_threshold
      handling_duration - self.class.handling_period_abbrev_reminder_window
    else
      nil
    end
  end

  def handling_expires
    confirmed? && (confirmed_at + handling_duration)
  end

  def handling_remaining
    confirmed? && [handling_expires - Time.zone.now, 0].max
  end

  def shipped_at_ago
    shipped? && (Time.zone.now.to_i - shipped_at.to_i)
  end

  def delivery_confirmation_requested_at_ago
    shipped? && (Time.zone.now.to_i - delivery_confirmation_requested_at.to_i)
  end

  def review_expires
    delivered? && (delivered_at + self.class.review_period_duration)
  end

  def review_remaining
    delivered? && [review_expires.to_i - Time.zone.now.to_i, 0].max
  end

  def expires_at
    created_at.to_time.to_i + Brooklyn::Application.config.listings.purchase.expire
  end

  def public?
    not private?
  end

  def make_public
    update_attribute(:private, false)
  end

  def make_private
    update_attribute(:private, true)
  end

  def report_non_delivery!
    send_email(:not_delivered_for_help, self)
  end

  def request_delivery_confirmation!
    logger.info("Requesting delivery confirmation for order #{id}")
    # gosh, wish I'd thought of "request delivery confirmation" nomenclature when I built these emails and
    # notifications
    inject_notification(:OrderDeliveryConfirmationPeriodElapsed, buyer_id, order_id: id)
    inject_notification(:OrderDeliveryConfirmationPeriodElapsed, listing.seller_id, order_id: id)
    send_email(:delivery_confirmation_period_elapsed_for_buyer, self)
    send_email(:delivery_confirmation_period_elapsed_for_seller, self)
    update_column(:delivery_confirmation_requested_at, Time.zone.now)
  end

  def follow_up_on_delivery_non_confirmation!
    logger.info("Following up on delivery non confirmation for order #{id}")
    send_email(:delivery_not_confirmed_for_help, self)
    update_column(:delivery_confirmation_followed_up_at, Time.zone.now)
  end

  def seller_has_default_deposit_account?
    listing.seller.default_deposit_account?
  end

  # Returns whether or not the necessary conditions hold for the order to be settled. In order for an order to be
  # settled, the seller must have a default deposit account.
  def settleable?
    listing.seller.default_deposit_account?
  end

  # Completes the order and settles if it is settleable, in the context of a single transaction.
  def complete_and_attempt_to_settle!
    transaction do
      complete!
      settle! if settleable?
    end
  end

  class << self
    # Retrieve a list of all delivered orders that have their review period expired.
    def find_delivered_review_expired
      expiration = Time.zone.now - review_period_duration
      (self.joins(:shipment).where(status: :delivered).merge(Shipment.delivered_before(expiration))).readonly(false)
    end

    # Retrieve a list of all unconfirmed orders that are more than +timeout+ minutes old.
    def find_expired(timeout)
      expiration = Time.zone.now - timeout.to_i.minutes
      self.where("created_at < ?", expiration).where(status: [:pending]).all
    end

    # Retrieve a list of all confirmed orders that haven't been shipped after their handling
    # duration and a buffer period, and should therefore be cancelled.
    def find_confirmed_unshipped_to_be_cancelled
      find_confirmed_past_handling_by(confirmed_unshipped_cancellation_buffer)
    end

    # Returns the orders which require manual delivery confirmation. These are shipped orders whose delivery
    # confirmation period has elapsed and have not yet had manual confirmation requested.
    #
    # @return [ActiveRecord::Relation]
    def find_to_request_delivery_confirmation
      # use includes rather than join since we predict that the shipments are going to be needed by the calling code.
      # if that turns out to not be true, we can change to joins.
      includes(:shipment, :listing).
        where(status: :shipped).
        where(delivery_confirmation_requested_at: nil).
        where("#{Shipment.quoted_table_name}.shipped_at < ?", delivery_confirmation_period_duration.ago)
    end

    # Yields each order which requires manual delivery confirmation.
    #
    # @yieldparam [Order] order
    # @see #find_to_request_delivery_confirmation
    def find_each_to_request_delivery_confirmation(&block)
      find_to_request_delivery_confirmation.find_each(&block)
    end

    # Returns the orders which require administrative followup due to delivery non confirmation. These are shipped
    # orders for which delivery confirmation was requested from the buyer but was never received.
    #
    # @return [ActiveRecord::Relation]
    def find_to_follow_up_on_delivery_non_confirmation
      where(status: :shipped).
      where(delivery_confirmation_followed_up_at: nil).
      where("#{quoted_table_name}.delivery_confirmation_requested_at < ?",
            delivery_non_confirmation_followup_period_duration.ago)
    end

    # Yields each order which requires followup due to delivery non-confirmation.
    #
    # @yieldparam [Order] order
    # @see #find_to_follow_up_on_delivery_non_confirmation
    def find_each_to_follow_up_on_delivery_non_confirmation(&block)
      find_to_follow_up_on_delivery_non_confirmation.find_each(&block)
    end

    # Retrieve a list of all confirmed orders that are past their handling period by
    # duration seconds.
    def find_confirmed_past_handling_by(duration)
      self.where(:status => :confirmed).joins(:listing).
        where('confirmed_at < (? - INTERVAL handling_duration SECOND)', duration.ago).
        readonly(false)
    end

    def find_for_user(user_id)
      #XXX-buyer-id move back to buyer_id: foo syntax when we drop buyer_id from listing
      joins(:listing).where("seller_id=? OR orders.buyer_id=?", user_id, user_id)
    end

    def bought_by_user(user_id)
      where("buyer_id=?", user_id)
    end

    def sold_by_user(user_id)
      joins(:listing).where("seller_id=?", user_id)
    end

    def sold_by_user_with_listings(user_id)
      sold_by_user(user_id).includes(:listing)
    end

    def updated_before(date)
      where("#{quoted_table_name}.updated_at < ?", date)
    end

    def updated_after(date)
      where("#{quoted_table_name}.updated_at > ?", date)
    end

    # Generate a unique reference number using #{REF_NUM_CHARS}
    def generate_reference_number
      loop do
        ref = (0...15).map{ REF_NUM_CHARS.to_a[rand(REF_NUM_CHARS.size)] }.join
        break ref unless where(:reference_number => ref).count > 0
      end
    end

    # Returns the subset of the provided user ids representing buyers who have completed at least one purchase.
    def find_purchaser_ids(ids)
      select(:buyer_id).with_status(:complete).where(buyer_id: ids).group(:buyer_id).having('COUNT(*) > 0').
        map(&:buyer_id)
    end
  end

  # A set of readable, non-confusing characters for reference number generation
  REF_NUM_CHARS = %w{ 2 3 4 6 7 9 A C D E F G H J K L M N P Q R T V W X Y Z}

  class IncompleteSettlement < Exception
    def initialize(exceptions = [])
      super("Some orders could not be settled: #{exceptions.map(&:message).join('; ')}")
    end
  end
end
