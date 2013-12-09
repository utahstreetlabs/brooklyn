module Stats
  module TutorialTracking
    extend ActiveSupport::Concern
    include Stats::Trackable

    delegate :track_tutorial_progress, to: 'self.class'

    module ClassMethods
      def track_tutorial_progress(step)
        if feature_enabled?(:onboarding, :tutorial_bar)
          track_usage(:tutorial_bar_progress, {completed_states: step})
        end
      end
    end
  end
end
