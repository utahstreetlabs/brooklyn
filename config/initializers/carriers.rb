require 'brooklyn/carrier'

Brooklyn::Carrier.configure(Brooklyn::Application.config.shipping)
Rails.logger.info("Allowing shipping via #{Brooklyn::Carrier.available.map(&:name)}")
