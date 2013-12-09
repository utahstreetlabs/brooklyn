class ShippingLabel < ActiveRecord::Base
  belongs_to :order
  belongs_to :cancelled_order

  mount_uploader :document, ShippingLabelDocumentUploader

  # note: a shipping label's tracking number is generated automatically by the carrier and returned from the external
  # shipping label provider when the label is generated. we store it with the label for archival purposes. it's also
  # stored with the shipment, but if the label expires, the shipment's tracking number (and carrier) are cleared so
  # that the seller can use basic shipping and specify new carrier and tracking number manually.
  attr_accessible :document, :remote_document_url, :url, :tracking_number, :tx_id, :expires_at

  state_machine :state, initial: :active do
    # active - within the window after generation when the label may be used to ship (upper bound determined by USPS)
    # expired - after the window has ended; may no longer be used to ship

    before_transition on: :expire do |label|
      label.expired_at = Time.zone.now
    end
    event :expire do
      transition active: :expired
    end
    after_transition on: :expire do |label|
      # clearing the shipment's attributes would trigger validation errors, so don't use validation
      label.order.shipment.carrier_name = nil
      label.order.shipment.tracking_number = nil
      label.order.shipment.save!(validate: false)
    end
  end

  def expires_in
    expires_at && [expires_at - Time.zone.now, 0].max
  end

  def cancel_order!
    self.cancelled_order_id = self.order_id
    self.order = nil
    save!
  end

  # Return a +File+ representing the label's document.
  # @return [File]
  # @raise [Exception] if the document cannot be downloaded from storage
  def to_file
    # thanks http://blog.bloomingame.com/?p=22
    document.retrieve_from_store!(File.basename(document.url))
    document.cache_stored_file!
    document.file
  end

  def media_type
    # Brooklyn::ShippingLabel creates all label documents in PDF format
    'application/pdf'
  end

  def suggested_filename
    I18n.t('models.shipping_label.suggested_filename', listing_title: order.listing.title.truncate(20),
      ship_date: created_at.to_date.strftime("%b %d"), extension: 'pdf')
  end

  # Returns a relation matching all shipping labels that need to be expired.
  #
  # @option options [ActiveSupport::TimeWithZone] :before (+Time.zone.now+) any unexpired label whose order is in
  # the confirmed state and that is scheduled to expire before this time will be matched
  # @return [ActiveRecord::Relation]
  def self.find_to_expire(options = {})
    joins(:order).where(orders: {status: :confirmed}).without_state(:expired).
      where("expires_at < ?", options.fetch(:before, Time.zone.now)).readonly(false)
  end

  def self.default_expire_after
    Brooklyn::Application.config.shipping.labels.expire_after
  end
end
