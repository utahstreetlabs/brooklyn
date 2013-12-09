if Rails.env.integration? || Rails.env.test? || Rails.env.development?
  Mocha::Configuration.allow(:stubbing_method_on_nil)
end
