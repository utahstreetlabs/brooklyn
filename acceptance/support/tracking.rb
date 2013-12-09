module Tracking
  shared_context 'tracking helpers' do
    def should_track_in_mixpanel(event, props)
      Brooklyn::Mixpanel.expects(:post).
          with(:track, has_entries(event: event, properties: has_entries(props)))
    end

    def with_live_usage_tracker
      original_driver = Brooklyn::UsageTracker.driver
      Brooklyn::UsageTracker.driver = Brooklyn::LiveUsageTracker.new
      begin
        yield
      ensure
        Brooklyn::UsageTracker.driver = original_driver
      end
    end

    def let_utmz_cookie(cookie)
      # only works for selenium, so only call this from a js: true scenario
      Capybara.current_session.driver.browser.set_cookie("__utmz=#{cookie}")
    end
  end
end

RSpec.configure do |config|
  config.include Tracking
end
