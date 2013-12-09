require 'datagrid'

class CancelledOrder < ActiveRecord::Base
  include OrderDatagrid
  include Orders::Api

  belongs_to :listing
  belongs_to :buyer, :class_name => 'User'
  has_one :shipping_address, class_name: 'PostalAddress', conditions: {ref_type: PostalAddress::RefType::SHIPPING},
          dependent: :destroy
  has_one :billing_address, class_name: 'PostalAddress', conditions: {ref_type: PostalAddress::RefType::BILLING},
          dependent: :destroy
  has_one :shipping_label, dependent: :destroy
  has_one :buyer_rating, dependent: :destroy
  has_one :seller_rating, dependent: :destroy
  has_many :annotations, as: :annotatable, dependent: :destroy

  ORDER_ATTRS_TO_REJECT = Set.new(['id', 'status', 'created_at', 'updated_at'])

  # open this up because we don't let users edit
  attr_accessible :listing_id, :uuid, :shipping_address_id, :bill_to_shipping, :confirmed_at, :shipped_at,
    :delivery_status_checked_at, :delivered_at, :completed_at, :settled_at, :canceled_at, :return_shipped_at,
    :return_delivered_at, :return_completed_at, :carrier, :tracking_number, :reference_number, :buyer_id,
    :previous_status, :private, :failure_reason, :billing_address_id, :payment_sid, :balanced_debit_url,
    :balanced_credit_url, :balanced_refund_url
  attr_accessor :failure_reason

  def self.create_from_order(order, attrs)
    cancelled_order = CancelledOrder.new(order.attributes.reject { |k, v| ORDER_ATTRS_TO_REJECT.include?(k) })
    cancelled_order.id = order.id
    cancelled_order.attributes = attrs
    annotations = order.annotations
    annotations.each do |annotation|
      annotation.annotatable_type = cancelled_order.class.name
    end
    CancelledOrder.transaction do
      cancelled_order.save!
      annotations.each do |a|
        a.save!
      end
    end
    # important - ensures annotations are not destroyed when order is destroyed
    order.annotations.reload
    cancelled_order
  end

  after_commit on: :create do
    CancelledOrders::AfterCreationJob.enqueue(self.id, failure_reason: self.failure_reason)
  end

  def discount
    0.00
  end

  def payment_type
    'Balanced'
  end

  def credit_amount
    0
  end

  def total_price
    listing.total_price
  end

  def shipment
    nil
  end

  def status
    :canceled
  end

  def human_status_name
    'Cancelled'
  end

  def status_events
    []
  end

  def can_confirm?
    false
  end

  def can_complete?
    false
  end

  def can_deliver?
   false
  end

  def can_settle?
    false
  end

  def can_ship?
    false
  end

  def can_cancel?
     false
  end

  def can_track?
    false
  end

  def was_confirmed_before_cancellation?
    ! (previous_status.nil? || previous_status.to_sym.in?([:pending]))
  end

  # Adds buyer and seller ratings to this order that describe a failed transaction. The seller rating's flag is set
  # to false, while the buyer rating's flag is left null to indicate that the system does not assign any
  # responsibility to the buyer for the failure.

  # @param [Symbol] reason the code describing the reason for the failed transaction (see OrderRating::FailureReasons)
  # @see OrderRating
  def create_failed_transaction_feedback!(reason)
    create_seller_rating!(user_id: listing.seller_id, purchased_at: confirmed_at, failure_reason: reason, flag: false)
    create_buyer_rating!(user_id: buyer_id, purchased_at: confirmed_at, failure_reason: reason, flag: nil)
  end

  def public?
    not private?
  end
end
