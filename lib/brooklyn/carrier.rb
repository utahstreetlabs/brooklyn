require 'ladon'

module Brooklyn
  class Carrier
    extend ActiveSupport::Memoizable
    include Ladon::Logging

    attr_reader :key, :name, :url

    def initialize(key, name, shipping_class, credentials, url)
      @key = key
      @name = name
      @shipping_class = shipping_class
      @credentials = credentials
      @url = url
    end

    def delivered?(tracking_number)
      client.find_tracking_info(tracking_number).status == :delivered
    end

    def client
      ActiveMerchant::Shipping.const_get(@shipping_class).new(@credentials)
    end
    memoize :client

    def clean_tracking_number(t)
      t.gsub(/\s/, '') if t
    end

    class << self
      extend ActiveSupport::Memoizable

      def class_for(carrier_name)
        n = "#{carrier_name.capitalize}"
        const_defined?(n) ? const_get(n) : self
      end

      def configure(config)
        @carriers = config.active.inject({}) do |h,c|
          carrier_conf = config.send(c)
          h[c] = class_for(c).new(c, carrier_conf.name, carrier_conf.klass, carrier_conf.credentials.marshal_dump,
            carrier_conf.url)
          h
        end
      end

      # an array of +Carrier+ objects representing carriers available for shipping
      def available
        @carriers.values
      end

      def for_key(key)
        @carriers[key.to_sym] if key
      end
    end

    class Usps < Carrier
      def clean_tracking_number(t)
        t = super
        # USPS hands out 30 digit tracking numbers that don't work with their API
        # the problem is extra digits at the front
        t && t.length == 30 ? t[-22..-1] : t
      end
    end
  end
end
