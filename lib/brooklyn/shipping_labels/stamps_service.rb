require 'brooklyn/shipping_labels/errors'
require 'brooklyn/shipping_labels/service_base'
require 'httpclient'
require 'stamps'
require 'tempfile'

module Brooklyn
  module ShippingLabels
    # A shipping label service backed by stamps.com.
    #
    # @see Stamps
    class StampsService < ServiceBase
      attr_reader :stamps, :http

      def initialize(config)
        super
        @stamps = Stamps.client
        @http = HTTPClient.new
        @http.connect_timeout = config.open_timeout
        @http.receive_timeout = config.read_timeout
      end

      # Creates a shipping label in stamps.com and returns a representation of it.
      #
      # @raise [Brooklyn::ShippingLabels::ShippingLabelException] for any sort of service failure (API error,
      #   connection timeout, i/o error)
      def generate!(params = {})
        stamps_params = {
          image_type: :Pdf,
          transaction_id: params[:local_tx_id],
          rate: rate_info(params[:shipping_option], params[:to][:zip_code], params[:from][:zip_code]),
          from: params[:from],
          to: params[:to]
        }
        stamps_params[:from][:zip_code] &&= fix_up_zip_code(stamps_params[:from][:zip_code])
        stamps_params[:to][:zip_code] &&= fix_up_zip_code(stamps_params[:to][:zip_code])
        msg = "Create #{params[:shipping_option]} shipping label (tx id #{params[:local_tx_id]})"
        stamp = benchmark_api_with_exception_handling(msg, stamps_params) do
          stamps.create!(stamps_params)
        end
        Label.new(
          tracking_number: stamp.tracking_number.to_s,
          url: stamp.url.to_s,
          tx_id: stamp.stamps_tx_id.to_s
        )
      end

      # Downloads and returns the shipping label document from stamps.com.
      # Note that this method downloads the document and creates a new file every time it's called.
      #
      # @raise [Brooklyn::ShippingLabels::ShippingLabelException] for any sort of service failure (API error,
      #   connection timeout, i/o error)
      # @raise [Exception] if there is an error storing the content locally or returning a reference to it
      def download(url)
        benchmark_with_exception_handling("Download shipping label #{url}") do
          Tempfile.open('shipping-label', config.download_cache_dir, encoding: 'ASCII-8BIT') do |cache|
            bytes = 0
            http.get_content(url) do |chunk|
              bytes += cache.write(chunk)
            end
            logger.debug("Wrote #{bytes} bytes from #{url} to #{cache.path}")
            cache
          end
        end
      end

      # Returns true if the identified label has any associated tracking events.
      #
      # Note that normally we filter out +ElectronicNotification+ tracking events since stamps.com automatically
      # generates and sends these to USPS for each shipment, but because their test environment does not support
      # any other type of tracking event, we keep those around to simulate getting other types of tracking events.
      #
      # @raise [Brooklyn::ShippingLabels::ShippingLabelException] for any sort of service failure (API error,
      #   connection timeout, i/o error)
      def shipped?(tx_id)
        track = benchmark_api_with_exception_handling("Checking shipment status for stamps tx #{tx_id}") do
          stamps.track(tx_id)
        end
        # when there is only one tracking event, it appears to come through as Hashie::Mash rather than an Array of
        # them.
        tracking_events = Array.wrap(track.tracking_events.tracking_event)
        if tracking_events.any?
          tracking_event_types = tracking_events.map { |te| te.tracking_event_type.to_s }
          logger.info("Received tracking events for stamps transaction #{tx_id}: #{tracking_event_types.join(', ')}")
          # filter out electronic notifications in production
          tracking_event_types = tracking_event_types.reject { |t| t == 'ElectronicNotification' } unless
            config.use_test_environment
          tracking_event_types.any?
        else
          logger.debug("Received no tracking events for stamps transaction #{tx_id}")
          false
        end
      end

      # Returns the first five digits of the given zip code, or +nil+ if the zip code doesn't begin with five digits.
      # Necessary because stamps.com requires this format for zip codes.
      def fix_up_zip_code(zip)
        return nil unless zip.present?
        return nil if (zip =~ /\A(\d{5})/).nil?
        $1
      end

      # Returns the rate information corresponding to the specified shipping option.
      #
      # @return [Hash]
      def rate_info(code, to_zip_code, from_zip_code)
        code = code.to_sym
        config.rates.key?(code) or
          raise UnsupportedShippingOption.new("Unsupported shipping option #{code}")
        rate = config.rates[code].reverse_merge(
          to_zip_code: to_zip_code,
          from_zip_code: from_zip_code,
          ship_date: Date.current.to_s
        )
        rate[:add_ons] = {add_on: [
          {type: 'US-A-DC'}, # delivery confirmation (so that we can track the shipment)
          {type: 'SC-A-HP'}  # hidden postage (don't show the seller how much the label cost)
        ]}
        rate
      end

      # Benchmarks the given block, guaranteeing that the benchmark result is logged even when an exception
      # is raised by the block. If an exception is raised, it is wrapped in +ShippingLabels::ShippingLabelException+.
      def benchmark_with_exception_handling(msg, &block)
        exception = nil
        rv = benchmark(msg) do
          begin
            yield
          rescue Exception => e
            exception = e
          end
        end
        if exception
          msg = "#{msg} - #{exception.class} (#{exception.message})"
#          logger.error("#{msg}:")
#          exception.backtrace.each { |f| logger.error("  #{f}") }
          raise ShippingLabels::ShippingLabelException.new(msg)
        end
        rv
      end

      # Benchmarks the given block as per +benchmark_with_exception_handling+. If the result is an invalid Stamps API
      # response, a +ShippingLabels::ShippingLabelException+ is raised.
      def benchmark_api_with_exception_handling(msg, params = {}, &block)
        rv = benchmark_with_exception_handling(msg, &block)
        if rv.respond_to?(:valid?) && !rv.valid?
          rv.errors.each do |error|
            error = error.downcase
            if error =~ /invalid destination address/
              raise ShippingLabels::InvalidToAddress.new(params[:to])
            elsif error =~ /invalid destination zip/
              raise InvalidToZipCode.new(params[:to][:zip_code])
            end
          end
          raise ApiException.new(msg, rv.errors)
        end
        rv
      end

      class ApiException < ShippingLabelException
        def initialize(web_method, errors = [])
          super("#{web_method}: #{Array(errors).compact.map(&:to_s).join('; ')}")
        end
      end

      class InvalidToZipCode < InvalidToAddress; end
    end
  end
end
