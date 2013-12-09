require 'rubygems'
require 'spork'
require 'database_cleaner'
require 'webmock/rspec'
require 'selenium/webdriver'

module RSpec
  module Core
    class ExampleGroup
      def clear_state
        @__memoized = nil
      end
    end

    class Example
      def clear_state
        @exception = nil
        example_group_instance.clear_state
      end
    end
  end
end

Spork.prefork do
  # needs to happen before loading Rails, as some Rails initializers connect to network services
  WebMock.allow_net_connect!

  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.
  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'
  require 'mocha/setup'
  require 'pyramid/resources/root_resource'
  require 'flying_dog/resources/root_resource'
  Resque.inline = true

  RSpec.configure do |config|
    #Fail after first failure
    config.fail_fast = true if Rails.env.integration?
    config.mock_with :mocha
    config.fixture_path = "#{::Rails.root}/spec/fixtures"
    # using database cleaner with truncation because some of the spec acceptance tests use selenium
    config.use_transactional_fixtures = false

    # if the environment variable +TEST_GROUP+ is specified in the format 1/2, 2/2 meaning "#1 of 2" and "#2 of 2"
    # then tests will be partitioned based on a modulo of their line number (disregarding file)
    test_group = ENV['TEST_GROUP'] && ENV['TEST_GROUP'].split('/').map(&:to_i) || []
    if test_group.count == 2
      id, count = test_group
      # using excluding because including is a union
      # ie. if we use including, then anything with a line number match *or* +js: true+ will get run in flakey
      # with excluding, it has to be js *and* line number match
      config.filter_run_excluding :line_number => lambda { |ln| (ln.to_i % count) != (id - 1) }
    end

    config.before(:suite) do
      # need feature flags to stick around since we use them to control which tests to run
      DatabaseCleaner.strategy = :truncation, {except: %w(feature_flags)}
    end
    # flush the feature flag cache to avoid feature flags set in one
    # spec from bleeding over into other specs
    config.before { FeatureFlag.flush_cache }

    config.before(:each) do
      DatabaseCleaner.start
      # XXX: remove when Rob lands his Redhook facade
      Redhook::Job::AddPerson.stubs(:perform)
      Redhook::Job::AddFollow.stubs(:perform)
      Redhook::Job::RemoveFollow.stubs(:perform)
      ProfileController.any_instance.stubs(:verify_recaptcha).returns(true)
      Signup::Buyer::ProfilesController.any_instance.stubs(:verify_recaptcha).returns(true)
    end

    # totally ripped from rspec-retry, cuz i can't make it work with our existing metadata
    config.around(:each) do |example|
      retry_count = example.metadata[:retry] || ENV.fetch('RSPEC_RETRY', 1).to_i
      retry_count = [retry_count, 1].max
      retry_count.times do |i|
        puts "Retry #{i} at #{@example.location}" if i > 0
        @example.clear_state
        example.run
        break if @example.exception.nil?
      end
      close_all_popup_windows
    end

    config.after(:each) do
      DatabaseCleaner.clean
      Lagunitas::Root.nuke
      Anchor::Root.nuke
      Redhook::Root.nuke
      Rubicon::Root.nuke
      #XXXrisingtide: make this work
      #RisingTide::Root.nuke
      Pyramid::RootResource.nuke
      FlyingDog::RootResource.nuke
      Sunspot.remove_all!
    end
  end

  Capybara.server_port = '54163'
  Capybara.app_host = "http://local.copious.com:#{Capybara.server_port}"
  # be careful setting this too high - it will slow down should_not tests by this amount
  # Capybara.default_wait_time = 30

  Capybara.javascript_driver = (ENV['JAVASCRIPT_DRIVER'] || 'selenium_firefox').to_sym
end

Spork.each_run do
  # This code will be run each time you run your specs.
  Dir[Rails.root.join("acceptance/support/**/*.rb")].each {|f| require f}
end

Capybara.register_driver :selenium_firefox do |app|
  profile = Selenium::WebDriver::Firefox::Profile.new
  profile.add_extension File.join(Rails.root, "acceptance/support/plugins/firebug.xpi")

  if ENV['FIREBUG_DEBUG']
    profile["extensions.firebug.console.enableSites"] = true
    profile["extensions.firebug.net.enableSites"]     = true
    profile["extensions.firebug.script.enableSites"]  = true
    profile["extensions.firebug.allPagesActivation"]  = "on"
  end

  Capybara::Selenium::Driver.new app, :browser => :firefox, :profile => profile
end

Capybara.register_driver :selenium_chrome do |app|
  Capybara::Selenium::Driver.new(app, :browser => :chrome)
end

Capybara.register_driver :capybara_with_headers do |app|
  Capybara::RackTest::Driver.new(app, headers: {'HTTP_USER_AGENT' => 'Opera/7.50 (Windows XP; U)'})
end

Capybara.register_driver :capybara_with_bot_agent do |app|
  Capybara::RackTest::Driver.new(app, headers: {'HTTP_USER_AGENT' => 'Googlebot'})
end
