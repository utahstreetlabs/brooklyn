module Orders
  module PrepaidShipping
    extend ActiveSupport::Concern

    def expired_shipping_label?
      shipping_label && shipping_label.expired?
    end

    # Directs the shipping label service to generate a shipping label and stores the returned information in the
    # order's associated shipment and shipping label.
    #
    # @return [ShippingLabel]
    # @see #generate_external_label!
    # @see #create_shipment_from_external_label!
    # @see #create_shipping_label_from_external_label!
    def create_prepaid_shipment_and_label!
      external_label = generate_external_label!
      transaction do
        create_shipment_from_external_label!(external_label)
        create_shipping_label_from_external_label!(external_label)
      end
    end

    # Directs the shipping label service to generate a shipping label.
    #
    # @return [Brooklyn::ShippingLabels::Label]
    # @raise [Exception] if the label cannot be generated
    # @see +Brooklyn::ShippingLabels::ServiceBase.generate!+
    def generate_external_label!
      SHIPPING_LABELS.generate!(
        local_tx_id: reference_number,
        shipping_option: listing.shipping_option.code,
        to: {
          full_name: buyer.name,
          address1: shipping_address.line1,
          address2: shipping_address.line2,
          city: shipping_address.city,
          state: shipping_address.state,
          zip_code: shipping_address.zip
        },
        from: {
          full_name: listing.seller.name,
          address1: listing.return_address.line1,
          address2: listing.return_address.line2,
          city: listing.return_address.city,
          state: listing.return_address.state,
          zip_code: listing.return_address.zip
        }
      )
    end

    # Creates and returns a shipment for this order based on the provided external label. Uses the tracking number
    # from the external label and the carrier name specified by +Brooklyn::ShippingLabels.carrier_name+.
    #
    # @param [Brooklyn::ShippingLabels::Label]
    # @return [Shipment]
    # @raise ActiveRecord::RecordNotSaved
    def create_shipment_from_external_label!(label)
      shipment = build_shipment(
        tracking_number: label.tracking_number,
        carrier_name: SHIPPING_LABELS.carrier_name
      )
      shipment.suppress_tracking_number_syntax_validation
      shipment.save!
      shipment
    end

    # Creates and returns a shipping label for this order based on the provided external label. The label document
    # is copied from the shipping label service to permanent storage.
    #
    # @param [Brooklyn::ShippingLabels::Label]
    # @return [ShippingLabel]
    # @raise ActiveRecord::RecordNotSaved
    def create_shipping_label_from_external_label!(label)
      options = {
        url: label.url,
        tracking_number: label.tracking_number,
        tx_id: label.tx_id,
        expires_at: ShippingLabel.default_expire_after.from_now
      }
      if label.document
        options[:document] = label.document
      else
        options[:remote_document_url] = label.url
      end
      create_shipping_label!(options)
    end
  end
end
