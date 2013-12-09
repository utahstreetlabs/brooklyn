require 'rubygems'
require 'spork'

Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.
  ENV["RAILS_ENV"] ||= 'test'
  ENV["SKIP_BALANCED"] = 'true'
  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'
  require 'mocha/setup'
  require 'timecop'

  RSpec.configure do |config|
    config.mock_with :mocha
    config.use_transactional_fixtures = true
    config.fixture_path = 'spec/fixtures/'
    config.include Capybara::DSL, type: :view
    # flush the feature flag cache to avoid feature flags set in one
    # spec from bleeding over into other specs
    config.before { FeatureFlag.flush_cache }
  end

  Sunspot.session = Sunspot::Rails::StubSessionProxy.new(Sunspot.session)
end

Spork.each_run do
  # This code will be run each time you run your specs.
  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

  RSpec.configure do |config|
    config.include ControllerHelpers, type: :controller
    config.include DashboardControllerHelpers, type: :controller
    config.include ViewHelpers, type: :view
    config.include ViewHelpers, type: :helper
    config.include RequestHelpers, type: :request
    config.include AttributeNormalizer::RSpecMatcher, :type => :model
  end
end
