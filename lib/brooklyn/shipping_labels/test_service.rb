require 'brooklyn/shipping_labels/errors'
require 'brooklyn/shipping_labels/service_base'

module Brooklyn
  module ShippingLabels
    # A shipping label service for test environments.
    class TestService < ServiceBase
      attr_accessor :label, :label_file

      def shipped
        @shipped ||= {}
      end

      # Returns +label+.
      def generate!(params = {})
        label
      end

      # Returns +label_file+.
      def download(url)
        label_file
      end

      # Returns true if +shipped+ is truthy.
      def shipped?(tx_id)
        shipped.fetch(tx_id, false)
      end
    end
  end
end
