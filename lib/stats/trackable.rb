require 'active_support/concern'
require 'brooklyn/usage_tracker'

module Stats
  module Trackable
    extend ActiveSupport::Concern
    include Brooklyn::MixpanelContext

    delegate :track_usage, :track_benchmark, to: 'self.class'

    module ClassMethods
      def track_usage(event, params = {}, &block)
        ret = yield if block_given?
        Brooklyn::UsageTracker.async_track(event, params) unless mixpanel_context[:skip_tracking]
        ret
      end

      def track_tutorial_progress(step)
        track_usage(:tutorial_bar_progress, {completed_states: step}) unless inviter?
      end

      # benchmark a method and track the results
      # implementation modeled on http://apidock.com/rails/ActiveRecord/Base/benchmark/class
      def track_benchmark(event, params)
        result = nil
        ms = Benchmark.ms { result = yield }
        track_usage(event, params.merge(benchmark: ms))
        result
      end
    end
  end
end
