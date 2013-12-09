require 'brooklyn/shipping_labels'

Stamps.configure do |config|
  config.integration_id = Brooklyn::Application.config.stamps.integration_id
  config.username       = Brooklyn::Application.config.stamps.username
  config.password       = Brooklyn::Application.config.stamps.password
  config.open_timeout   = Brooklyn::Application.config.stamps.open_timeout
  config.read_timeout   = Brooklyn::Application.config.stamps.read_timeout
  config.log_messages   = true
  config.format         = :hashie

  config.endpoint = Stamps::Configuration::TEST_ENDPOINT if Brooklyn::Application.config.stamps.use_test_environment
end

# has to be done after Stamps.configure because it calls Savon.configure under the hood and doesn't give us access
Savon.configure do |config|
  config.logger = Rails.logger
end

SHIPPING_LABELS = Brooklyn::ShippingLabels.create(Brooklyn::Application.config.stamps)

Rails.logger.info("Accessing stamps.com as #{Stamps.username} with integration id #{Stamps.integration_id} at #{Stamps.endpoint}")
