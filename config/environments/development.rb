Brooklyn::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Uncomment to enable production-like asset_hattery
  # config.consider_all_requests_local       = false
  # config.action_controller.perform_caching = true

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = true

  # Don't care if we don't have TLS -- uncomment to have all mail
  # be delivered locally
  config.action_mailer.smtp_settings = {
    :openssl_verify_mode => OpenSSL::SSL::VERIFY_NONE
  }

  # need this in background jobs, so can't just get it from request environment.
  config.action_mailer.default_url_options = { host: 'local.copious.com:3000' }
  config.action_mailer.asset_host = "http://local.copious.com:3000"

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Configure the logger.
  require 'brooklyn/logger'
  config.logger = Brooklyn::Logger.new({ :use_syslog   => 0,
                                         :log_file     => "#{Rails.root}/log/development.log",
                                         :log_facility => Syslog::LOG_USER,
                                         :log_level    => Syslog::LOG_DEBUG,
                                         :log_name     => "brooklyn"})
  # Do not compress assets
  config.assets.compress = false

  # This wreaks some havoc reloading javascript/css
  config.assets.digest = false

  # Expands the lines which load the assets
  config.assets.debug = true

  config.assets.precompile << 'jquery_all.js'

  # use cloudfront for assets, because it rulez
  # config.action_controller.asset_host = "//d3c8s0pc8b2u61.cloudfront.net"
  # config.action_mailer.asset_host = "http://d3c8s0pc8b2u61.cloudfront.net"

  # Search

  config.search.commit_on_write = true

  # Upload files to S3

  config.files.s3.bucket = "utahstreetlabs-dev-#{ENV['USER']}"

  # Application event tracking

  config.tracking.mixpanel.token = ''

  # Application event logging

  config.event_logging.use_syslog = false

  # Social networks

  config.networks.tumblr.app_id = ''
  config.networks.tumblr.app_secret = ''

  config.orders.delivery_confirmation_period_duration = 1.hour
  config.orders.delivery_non_confirmation_followup_period_duration = 1.hour

#  +------+----------+
#  | id   | slug     |
#  +------+----------+
#  | 1316 | dog-tags |
#  |   31 | handmade |
#  |   33 | store    |
#  |   29 | usps     |
#  +------+----------+

#  +-----+----------------------------------+
#  | id  | email                            |
#  +-----+----------------------------------+
#  +-----+----------------------------------+

  config.users.signup.curated = [
  ]

  # uncomment to use stub redhook data in dev
  # config.redhook.stub = true

  # set to true if you want dev-tweaks to log when reloader hooks are skipped
  config.dev_tweaks.log_autoload_notice = false

  config.js_sdk.host = 'local.copious.com:3000'
  config.bookmarklet.host = 'http://local.copious.com:3000'
  config.bookmarklet.domain = 'local.copious.com:3000'

  config.home.collection_carousel.window = 1.month # because we probably have many fewer follows in our dbs
end

SslRequirement.disable_ssl_check = true
Vanity.playground.collecting = true
