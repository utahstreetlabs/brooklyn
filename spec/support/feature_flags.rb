module FeatureFlags
  def feature_flag(name, enabled = true)
    let!("#{name}_flag") { FeatureFlag.where(name: name).first! }
    let!("#{name}_flag_original_value") { send("#{name}_flag").enabled? }
    before { send("#{name}_flag").update_attributes!(enabled: enabled) }
    after { send("#{name}_flag").update_attributes!(enabled: send("#{name}_flag_original_value")) }
  end
end

RSpec.configure do |config|
  config.extend(FeatureFlags)
end
