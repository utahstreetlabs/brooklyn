Airbrake.configure do |config|
  config.api_key = ''
  config.development_environments += %w{integration}
  config.params_filters.concat [:password, :card_number, :'expires_on(1i)', :'expires_on(2i)', :'expires_on(3i)',
                                :security_code]
end
