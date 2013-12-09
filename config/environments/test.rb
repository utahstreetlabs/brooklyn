Brooklyn::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # The test environment is used exclusively to run your application's
  # test suite.  You never need to work with it otherwise.  Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs.  Don't rely on the data there!
  config.cache_classes = true

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection    = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test
  config.action_mailer.default_url_options = { :host => 'example.com' }
  config.action_mailer.asset_host = "http://example.com"

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Print deprecation notices to the stderr
  config.active_support.deprecation = :stderr

  #Set required number of interests
  config.interests.signup.required = 5

  # Configure the logger.
  require 'brooklyn/logger'
  config.logger = Brooklyn::Logger.new({ :use_syslog   => 0,
                                         :log_file     => "#{Rails.root}/log/test.log",
                                         :log_facility => Syslog::LOG_USER,
                                         :log_level    => Syslog::LOG_DEBUG,
                                         :log_name     => "brooklyn"})

  # Copious services

  config.lagunitas.port = 4001
  config.anchor.port = 4011
  config.redhook.port = 4021
  config.rubicon.port = 4031
  config.rising_tide.drpc.servers = 'localhost:4051'
  config.pyramid.port = 4061
  config.flyingdog.port = 4071

  # Search

  config.search.commit_on_write = true

  # Upload files to the local filesystem

  config.files = OpenStruct.new(
    local: OpenStruct.new(dir: ::File.join('uploads', Rails.env))
  )

  # Application event logging

  config.event_logging.use_syslog = false

  # Decrease the expense of generating passwords for test users

  config.security.passwords.cost = 1

  # Listing sync

  config.sync.listings.active_sources = [:ajm]

  # Social networks

  config.networks.registerable = [:facebook, :twitter]

  config.networks.instagram.app_id = ''
  config.networks.instagram.app_secret = ''

  config.js_sdk.host = 'example.com'
  config.bookmarklet.host = 'example.com'
  config.bookmarklet.domain = 'local.copious.com:54163'
  config.flash.duration = 99999 # very long time so flashes persist

  config.users.scheduled_follows = {}
end

SslRequirement.disable_ssl_check = true
OmniAuth.config.test_mode = true
