require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/memoizable'

module Network
  mattr_accessor :config
  @@config ||= Brooklyn::Application.config.networks

  class NotConnected < Exception
    attr_reader :network

    def initialize(network, msg = nil)
      super(msg)
      @network = network
    end
  end

  class << self
    extend Brooklyn::Memoizable

    # We consider the list of known networks to be any in the configuration
    # that respond_to?(:url).
    def known
      self.config.marshal_dump.keys.inject([]) do |m, n|
        self.config.send(n).respond_to?(:url) ? m << n.to_sym : m
      end
    end
    memoize :known

    def registerable
      self.config.respond_to?(:registerable) ? self.config.registerable : []
    end
    memoize :registerable

    def active
      self.config.respond_to?(:active) ? self.config.active : []
    end
    memoize :active

    def shareable
      self.config.respond_to?(:shareable) ? self.config.shareable : []
    end
    memoize :shareable

    def autoshareable
      self.config.respond_to?(:autoshareable) ? self.config.autoshareable : []
    end
    memoize :autoshareable

    def klass(network)
      if network.to_sym == :instagram_secure
        "Network::Instagram::Secure".constantize
      else
        "Network::#{network.to_s.camelize}".constantize
      end
    end
    memoize :klass

    def auth_callback_path(network, options = {})
      network_klazz = Network.klass(network)
      raise ArgumentException, "unknown network #{network}" unless network_klazz
      target_path = network_klazz.auth_callback_path(options)
    end

    def external_share_dialog_url(network, params={}, options={})
      network_klazz = Network.klass(network)
      raise ArgumentException, "unknown network #{network}" unless network_klazz
      target_url = network_klazz.external_share_dialog_url(params, options)
      target_url
    end
  end
end
