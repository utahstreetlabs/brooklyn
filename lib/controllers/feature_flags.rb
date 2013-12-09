module Controllers
  module FeatureFlags
    extend ActiveSupport::Concern

    included do
      before_filter do
        FeatureFlag.setup(admin: admin?)
      end

      after_filter do
        FeatureFlag.flush_cache
      end
    end
  end
end
