require 'active_support/benchmarkable'
require 'ladon'

module Brooklyn
  module ShippingLabels
    class ServiceBase
      include ActiveSupport::Benchmarkable
      include Ladon::ErrorHandling
      include Ladon::Logging

      attr_reader :config

      def initialize(config)
        @config = config
      end

      # Returns the name of the shipping carrier associated with this label service. For now, we only support shipping
      # label services that use USPS.
      #
      # @return [Symbol]
      def carrier_name
        :usps
      end

      # Creates a shipping label in the external service and returns a representation of it.
      #
      # @option params [String] :local_tx_id uniquely identifies the transaction from the brooklyn client's perspective;
      #   used to retry a failed generate operation
      # @option params [Symbol] :shipping_option the unique code for the prepaid shipping option associated with the
      #   label to be generated; mapped by the driver to a service-specific set of rate information
      # @option params [Hash] :from the return address
      # @option from [String] :full_name the first and last name of the seller
      # @option from [String] :address1 the primary (street) address of the seller
      # @option from [String] :address2 the secondary address (apt, etc) of the seller
      # @option from [String] :city the city of the seller
      # @option from [String] :state the state of the seller
      # @option from [String] :zip_code the zip code of the seller
      # @option params [Hash] :to the delivery address
      # @option to [String] :full_name the first and last name of the buyer
      # @option to [String] :address1 the primary (street) address of the buyer
      # @option to [String] :address2 the secondary address (apt, etc) of the buyer
      # @option to [String] :city the city of the buyer
      # @option to [String] :state the state of the buyer
      # @option to [String] :zip_code the zip code of the buyer
      #
      # @return [Brooklyn::ShippingLabels::Label]
      # @raise [Brooklyn::ShippingLabels::ShippingLabelException] if the label cannot be generated
      def generate!(params = {})
        raise NotImplementedError
      end

      # Downloads and returns the shipping label document from the external service.
      #
      # @param [String] url the url of the shipping label document
      # @return [Tempfile]
      # @raise [Brooklyn::ShippingLabels::ShippingLabelException] if the label cannot be downloaded
      def download(url)
        raise NotImplementedError
      end

      # Returns whether or not the labeled parcel has entered the carrier's system.
      #
      # @param [String] tx_id the label provider's transaction id associated with the label.
      # @return [Boolean]
      # @raise [Brooklyn::ShippingLabels::ShippingLabelException] if the label cannot be downloaded
      def shipped?(tx_id)
        raise NotImplementedError
      end
    end
  end
end
