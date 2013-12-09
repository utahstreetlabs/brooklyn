Brooklyn::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Specifies the header that your server uses for sending files
#  config.action_dispatch.x_sendfile_header = "X-Sendfile"

  # For nginx:
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Use a different logger for distributed setups
  config.colorize_logging = false

  # Configure the logger.
  require 'brooklyn/logger'
  config.logger = Brooklyn::Logger.new({ :use_syslog   => 1,
                                         :log_facility => Syslog::LOG_USER,
                                         :log_level    => Syslog::LOG_DEBUG,
                                         :log_name     => "brooklyn"})

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Disable Rails's static asset server
  # In production, Apache or nginx will already do this
  config.serve_static_assets = false

  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # need this in background jobs, so can't just get it from request environment.
  config.action_mailer.default_url_options = { host: 'stage.copious.com' }

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Choose the compressors to use
  # config.assets.js_compressor  = :uglifier
  # config.assets.css_compressor = :yui

  # Don't compile assets - they should be compiled to the cdn
  config.assets.compile = false

  # use cloudfront for assets, because it rulez
  config.action_controller.asset_host = ""
  config.action_mailer.asset_host = ""

  # Use jquery and jquery ui from here: http://code.google.com/apis/libraries/devguide.html#jquery
  config.assets.use_jquery_cdn = true

  # Defaults to Rails.root.join("public/assets")
  # config.assets.manifest = YOUR_PATH

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # config.assets.precompile += %w( search.js )

  # Copious services

  config.lagunitas.host = 'staging3.copious.com'
  config.lagunitas.port = 4002
  config.anchor.host = 'staging4.copious.com'
  config.anchor.port = 4012
  config.redhook.host = 'staging3.copious.com'
  config.redhook.port = 4020
  config.rubicon.host = 'staging3.copious.com'
  config.rubicon.port = 4030
  config.rising_tide.stories.host = 'staging4.copious.com'
  config.rising_tide.shard_config.host = 'staging4.copious.com'
  config.rising_tide.active_users.host = 'staging4.copious.com'
  config.rising_tide.card_feeds.feed_1.host = 'staging4.copious.com'
  config.rising_tide.card_feeds.feed_1.db = 2
  config.rising_tide.card_feeds.everything_card_feed.host = 'staging4.copious.com'
  config.rising_tide.drpc.servers = 'staging6.copious.com:4050'
  config.pyramid.host = 'staging4.copious.com'
  config.pyramid.port = 4060
  config.flyingdog.host = 'staging4.copious.com'
  config.flyingdog.port = 4070

  # Redis

  config.redis.resque.host = 'staging3.copious.com'
  config.redis.cache.host = 'staging3.copious.com'
  config.redis.vanity.host = 'staging3.copious.com'

  # Search

  config.search.commit_on_write = true

  # the Balanced arketplace named "Copious Staging"
  config.balanced.api_key.secret = ''

  # Google Analytics

  config.google_analytics.account_id = ''

  # Application event tracking

  config.tracking.mixpanel.token = ''

  config.tracking.google.adwords.signup.conversion_id = ''
  config.tracking.google.adwords.signup.conversion_label = ''
  config.tracking.google.adwords.newlisting.conversion_id = ''
  config.tracking.google.adwords.newlisting.conversion_label = ''
  config.tracking.google.adwords.startlisting.conversion_id = ''
  config.tracking.google.adwords.startlisting.conversion_label = ''

  # Social networks

  config.networks.hidden_for_users = []

  config.networks.tumblr.app_id = ''
  config.networks.tumblr.app_secret = ''

  config.networks.instagram.app_id = ''
  config.networks.instagram.app_secret = ''
  config.networks.instagram.app_id_secure = ''
  config.networks.instagram.app_secret_secure = ''

  # Custom order job scheduling

  config.orders.review_period_duration = 5.minutes
  config.orders.confirmed_unshipped_cancellation_buffer = 5.minutes
  config.orders.delivery_confirmation_period_duration = 5.minutes
  config.orders.delivery_non_confirmation_followup_period_duration = 6.hours

  # Credits / offers / etc.

  config.credits.invitee.min_followers = 2
  config.offers.min_followers = 2
  config.invites.max_creditable_acceptances = 2

  config.shipping.labels.expire_after = 2.days

  config.users.notifications.autoclear_viewed_period = 1.hour

  config.js_sdk.host = 'stage.copious.com'
  # We can't have multiple CNAMEs on a S3 bucket, so we just use the sdk one.
  # Note that we include s3.amazonaws.com here so that https websites work with
  # the bookmarklet in staging; can be removed if we set up proxying.
  config.bookmarklet.host = '//s3.amazonaws.com/sdk-staging.copious.com'
  config.bookmarklet.domain = 'stage.copious.com'
end
Vanity.playground.collecting = true
