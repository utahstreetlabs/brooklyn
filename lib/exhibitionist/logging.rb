require 'active_support/concern'
require 'logger'

module Exhibitionist
  def self.default_logger
    defined?(Rails) ? Rails.logger : ::Logger.new($stdout)
  end

  def self.logger
    @logger = default_logger unless instance_variable_defined?(:@logger)
    @logger
  end

  def self.logger=(logger)
    @logger = logger
  end

  module Logging
    extend ActiveSupport::Concern

    def logger
      self.class.logger
    end

    module ClassMethods
      def logger
        Exhibitionist.logger
      end
    end
  end
end
