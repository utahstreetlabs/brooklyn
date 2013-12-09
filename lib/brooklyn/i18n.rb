require 'i18n'

# Extend I18n::Backend::Simple to support a/b testing localization strings.
# The backend is designed to be extended like this - see
# https://github.com/svenfuchs/i18n/blob/master/lib/i18n/backend/simple.rb#L3
module Brooklyn
  module I18n

    # Given a datastructure pulled from an i18n backend, extract an appropriate
    # value given the A/B test cohort the current user is in for the specified
    # experiment.
    #
    # The datastructure expected by this method looks like this:
    # love:                 # the i18n key
    #   ab:                 #
    #     want_love:        # the experiment name
    #       love: 'Love'    # alternative 1
    #       want: 'Want'    # alternative 2
    #       default: 'Love' # for use when the feature is not enabled
    #
    # This method expects a feature flag named "experiments.#{experiment_name}" to exist
    # and will look for a default value if the feature is not enabled.
    def ab_test_copy(data)
      if data.is_a?(Hash) && data[:ab]
        experiment, variants = data[:ab].first
        if feature_enabled?("experiments.#{experiment}")
          variants[ab_test(experiment).to_sym]
        else
          variants[:default] || variants.values.first
        end
      else
        data
      end
    end
  end
end
