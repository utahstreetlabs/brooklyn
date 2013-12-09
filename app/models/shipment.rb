require 'brooklyn/carrier'
require 'brooklyn/sprayer'

class Shipment < ActiveRecord::Base
  include Brooklyn::Sprayer

  belongs_to :order
  delegate :shipped, :ship!, :shipped?, :deliver, :deliver!, :delivered?, :shipping_label, to: :order

  validates :tracking_number, presence: true,
    tracking_number: {carrier_field: :carrier_name, allow_blank: true,
                      unless: :suppress_tracking_number_syntax_validation?}
  validates_uniqueness_of :return, scope: :order_id

  normalize_attributes :carrier_name, :tracking_number

  # ensure tracking number is cleaned after carrier is configured
  after_initialize { self.tracking_number = tracking_number }

  attr_accessible :carrier_name, :tracking_number

  def suppress_tracking_number_syntax_validation
    @suppress_tracking_number_syntax_validation = true
  end

  def enable_tracking_number_validation
    @suppress_tracking_number_syntax_validation = false
  end

  def suppress_tracking_number_syntax_validation?
    !!@suppress_tracking_number_syntax_validation
  end

  # When the tracking number is updated at any point after the shipment was created, that's a big change to the
  # expectations of the seller and buyer, so we have to notify them.
  def enqueue_tracking_number_update_job_if_necessary
    if previous_changes.key?('tracking_number')
      Shipments::AfterTrackingNumberUpdateJob.enqueue(self.id)
    end
  end
  after_commit :enqueue_tracking_number_update_job_if_necessary, on: :update

  # Checks the shipping label service to see if the shipment has been shipped yet and transitions the order to the
  # +shipped+ state if it has been.
  #
  # @see +Brooklyn::ShippingLabels::ServiceBase.shipped?+
  def check_and_update_prepaid_shipment_status!
    update_attribute(:shipment_status_checked_at, Time.zone.now)
    ship! if SHIPPING_LABELS.shipped?(shipping_label.tx_id)
  end

  # Update shipping status based on tracking info from carrier
  def check_and_update_delivery_status!
    update_attribute(:delivery_status_checked_at, Time.zone.now)
    deliver! if dummy_tracking? || (carrier && carrier.delivered?(tracking_number))
  end

  # Returns true if we're not in production and the shipment uses the dummy UPS tracking number that we tend to use
  # in development and staging.
  def dummy_tracking?
    !Rails.env.production? && carrier && carrier.key == :ups && tracking_number == '1Z9999999999999999'
  end

  def carrier
    @carrier ||= Brooklyn::Carrier.for_key(self.carrier_name)
  end

  def tracking_number=(tracking_number)
    write_attribute(:tracking_number, normalize_tracking_number(tracking_number))
  end

  def normalize_tracking_number(tracking_number)
    if tracking_number.present?
      # Note that upcase only affects ascii, but that should be fine for tracking numbers.
      tracking_number = tracking_number.upcase
      tracking_number = carrier.clean_tracking_number(tracking_number) if carrier
    end
    tracking_number
  end

  class << self
    # XXX: replaced by Shipments::CheckDeliveryStatusJob. remove after prepaid shipping ships.
    # find all shipments that have not been delivered and need to have their deliery status rechecked
    # then check them all
    # raises exception on any tracking errors
    def check_all_delivery_statuses
      Shipment.find_delivery_checkable.each do |shipment|
        begin
          shipment.check_and_update_delivery_status!
        rescue ActiveMerchant::Shipping::ResponseError => e
          # this often happens before the carrier has updated their site, so just chill
          if shipment.created_at > Time.now - 1.day
            Rails.logger.warn("Caught exception checking shipment tracking: #{e.message} for #{shipment.inspect}. Shipment is less than a day old, so not Airbraking yet.")
          else
            notify_shipment_tracking_exception(e, shipment)
          end
        rescue => e
          notify_shipment_tracking_exception(e, shipment)
        end
      end
    end

    # XXX: replaced by Shipments::CheckDeliveryStatusJob. remove after prepaid shipping ships.
    def notify_shipment_tracking_exception(e, shipment)
      Rails.logger.error("Caught exception checking shipment tracking: #{e.message} for #{shipment.inspect}")
      Airbrake.notify(e, parameters: {shipment_id: shipment.id, carrier: shipment.carrier_name, tracking_number: shipment.tracking_number, order_id: shipment.order_id})
    end

    def find_delivery_checkable
      max_ship_time = Time.zone.now - delivery_status_check_delay
      max_check_time = Time.zone.now - delivery_status_recheck_delay
      table = self.quoted_table_name
      # UPS doesn't appear to be reporting expected delivery times, so we'll just ensure some reasonable time has passed
      # since shipping occured
      self.where(delivered_at: nil).where("(#{table}.created_at < ? AND #{table}.delivery_status_checked_at IS NULL)
        OR #{table}.delivery_status_checked_at < ?", max_ship_time, max_check_time)
    end

    def delivered_before(datetime)
      self.where("#{self.quoted_table_name}.delivered_at < ?", datetime)
    end
  end

  # Returns a relation matching the shipments for confirmed orders with active prepaid shipping labels whose status
  # check delay has expired.
  #
  # @options options [Integer] :delay (+#shipment_status_check_delay+) the number of seconds that must
  #   elapse between the previous status check and the subsequent one
  # @return [ActiveRecord::Relation]
  def self.find_prepaid_shipment_checkable(options = {})
    delay = options.fetch(:delay, shipment_status_check_delay)
    status_checked_at_col = "#{quoted_table_name}.shipment_status_checked_at"
    joins(order: :shipping_label).
      readonly(false).
      where(orders: {status: :confirmed}).
      where(shipping_labels: {state: :active}).
      where("#{status_checked_at_col} IS NULL OR #{status_checked_at_col} < ?", delay.ago)
  end

  def self.config
    Brooklyn::Application.config.shipments
  end

  def self.shipment_status_check_delay
    config.shipment_status_check_delay
  end

  def self.delivery_status_check_delay
    config.delivery_status_check_delay
  end

  def self.delivery_status_recheck_delay
    config.delivery_status_recheck_delay
  end
end
