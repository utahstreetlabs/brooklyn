module Kernel
  def feature_enabled?(*scopes)
    FeatureFlag.enabled?(*scopes)
  end
end
