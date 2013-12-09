require 'balanced'

balanced_options = {
  logger: Rails.logger,
  connection_timeout: Brooklyn::Application.config.balanced.connection_timeout,
  read_timeout: Brooklyn::Application.config.balanced.read_timeout
}

marketplace = unless ENV['SKIP_BALANCED'].present?
    if Rails.env.test? || Rails.env.integration?
    # create a new marketplace for every test run
    key = Balanced::ApiKey.new.save
    Balanced.configure(key.secret, balanced_options)
    Balanced::Marketplace.new.save
  elsif Rails.env.development?
    cfg = File.join(Rails.root, 'config', 'balanced.txt')
    if File.exists?(cfg)
      # use the already-configured marketplace for this Brooklyn sandbox
      secret = File.read(cfg)
      Balanced.configure(secret, balanced_options)
      Balanced::Marketplace.my_marketplace
    else
      # create a marketplace for this sandbox and store its secret in a git-ignored config file
      key = Balanced::ApiKey.new.save
      Balanced.configure(key.secret, balanced_options)
      marketplace = Balanced::Marketplace.new.save
      Rails.logger.debug("Writing Balanced api key secret to #{cfg}")
      File.open(cfg, "w") { |f| f.write(key.secret) }
      marketplace
    end
  else
    Balanced.configure(Brooklyn::Application.config.balanced.api_key.secret, balanced_options)
    Balanced::Marketplace.my_marketplace
  end
end

Rails.logger.info("Processing payments with Balanced at #{marketplace.uri}") if marketplace
