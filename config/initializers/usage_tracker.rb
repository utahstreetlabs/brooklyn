require 'brooklyn/usage_tracker'

Brooklyn::UsageTracker.driver = (Rails.env.test? || Rails.env.integration?) ? Brooklyn::TestUsageTracker.new :
  Brooklyn::LiveUsageTracker.new
