class ShippingOption < ActiveRecord::Base
  # Returns the currently active shipping option codes. These options are available for selection when posting a new
  # listing.
  #
  # @return [Array]
  def self.active_option_codes
    config.active
  end

  # Returns the configurations for the currently active shipping options.
  #
  # @return [Hash] option code => option config
  # @see #active_option_codes
  def self.active_option_configs
    active_option_codes.each_with_object({}) { |code, m| m[code] = config.send(code) }
  end

  # Returns the configuration for the identified shipping option, if it exists and is active.
  #
  # @see #active_option_configs
  def self.active_option_config(code)
    active_option_configs[code]
  end

  # Returns the configuration for the identified shipping option if it exists, regardless of whether or not the
  # option is active.
  def self.option_config(code)
    config.respond_to?(code) && config.send(code)
  end

  def self.config
    Brooklyn::Application.config.prepaid_shipping
  end

  belongs_to :listing

  validates :code, presence: true, length: {maximum: 32, allow_blank: true},
    inclusion: {in: active_option_codes, allow_blank: true}
  validates :rate, presence: true, numericality: {greater_than: 0, allow_blank: true}

  def basic_image_url
    config.basic_image_url
  end

  def step2_image_url
    config.step2_image_url
  end

  def step3_image_url
    config.step3_image_url
  end

  def pickup_schedulable?
    !!config.pickup_schedulable
  end

  def config
    self.class.option_config(self.code)
  end

  def copy_from_config!(code)
    code = code.to_sym
    cfg = self.class.config.send(code)
    self.code = code
    self.rate = cfg.rate
  end
end
