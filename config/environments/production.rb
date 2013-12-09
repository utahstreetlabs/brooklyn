Brooklyn::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.action_dispatch.rack_cache[:verbose] = false

  # Specifies the header that your server uses for sending files
  config.action_dispatch.x_sendfile_header = "X-Sendfile"

  # For nginx:
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Use a different logger for distributed setups
  # Configure the logger.
  require 'brooklyn/logger'
  config.logger = Brooklyn::Logger.new({ :use_syslog   => 1,
                                         :log_facility => Syslog::LOG_USER,
                                         :log_level    => Syslog::LOG_DEBUG,
                                         :log_name     => "brooklyn"})
  config.colorize_logging = false

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
  config.action_mailer.default_url_options = { host: 'copious.com' }

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

  # Jobs
  config.jobs.stories.batch_blacklist = [38319, 11089]
  config.jobs.email_listing_activated_blacklist = [38319, 11089]

  # Copious services

  config.lagunitas.host = 'services.copious.com'
  config.lagunitas.port = 4002
  config.anchor.host = 'services.copious.com'
  config.anchor.port = 4012
  config.redhook.host = 'services.copious.com'
  config.redhook.port = 4022
  config.redhook.host_count = 2
  config.rubicon.host = 'services.copious.com'
  config.rubicon.port = 4032
  config.rising_tide.stories.host = 'rt-stories-redis-slave.copious.com'
  config.rising_tide.shard_config.host = 'rt-shard-config-redis.copious.com'
  config.rising_tide.active_users.host = 'rt-active-users-redis.copious.com'
  config.rising_tide.card_feeds.everything_card_feed.host = 'rt-feeds-1-redis.copious.com'
  config.rising_tide.card_feeds.feed_1.host = 'rt-feeds-1-redis.copious.com'


  config.rising_tide.drpc.servers = ['drpc1.copious.com:4050', 'drpc2.copious.com:4050']
  config.pyramid.host = 'services.copious.com'
  config.pyramid.port = 4062
  config.flyingdog.host = 'flyingdog.copious.com'
  config.flyingdog.port = 4072

  # Redis

  config.redis.resque.host = 'resque-redis-master.copious.com'
  config.redis.cache.host = 'cache-redis-master.copious.com'
  config.redis.vanity.host = 'cache-redis-master.copious.com'
  config.redis.vanity.db = 1

  # Google Analytics

  config.google_analytics.account_id = 'UA-23540971-1'

  # Application event tracking

  config.tracking.mixpanel.token = 'c1c03b5e26cec56272f26794d85651b9'

  config.tracking.google.adwords.signup.conversion_id = ''
  config.tracking.google.adwords.signup.conversion_label = ''
  config.tracking.google.adwords.newlisting.conversion_id = ''
  config.tracking.google.adwords.newlisting.conversion_label = ''
  config.tracking.google.adwords.startlisting.conversion_id = ''
  config.tracking.google.adwords.startlisting.conversion_label = ''
  config.tracking.google.adwords.firstlisting.conversion_id = ''
  config.tracking.google.adwords.firstlisting..conversion_label = ''
  config.tracking.google.adwords.registration.conversion_id = ''
  config.tracking.google.adwords.registration.conversion_label = ''
  config.tracking.google.adwords.purchase_complete.conversion_id = ''
  config.tracking.google.adwords.purchase_complete.conversion_label = ''

  config.tracking.xanet.id = ''
  config.tracking.optimal.id = ''

  # Social networks

  config.networks.active = [:facebook, :twitter, :tumblr, :instagram]
  config.networks.registerable = [:facebook, :twitter]
  config.networks.hidden_for_users = ['boo-the-dog']

  config.networks.instagram.app_id = ''
  config.networks.instagram.app_secret = ''
  config.networks.instagram.app_id_secure = ''
  config.networks.instagram.app_secret_secure = ''

  # Curation

  config.users.signup.curated = []

  # Feature flags

  config.stamps.use_test_environment = false
  config.stamps.username = ''
  config.stamps.password = ''

  # Listing sync

  config.sync.listings.active_sources = []

  config.balanced.api_key.secret = ''
  # For realz live bank account
  # The current account must always be first
  config.balanced.marketplace_bank_accounts = [
    OpenStruct.new(
      name: '',
      number: '',
      last_four: '',
      routing_number: ''
    )
  ]

  config.js_sdk.host = 'copious.com'
  config.bookmarklet.host = ''
end
