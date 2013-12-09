if Rails.env.development?
  ActionMailer::Base.smtp_settings = {
    # assumes mailcatcher is running
    address: 'localhost',
    port: 1025
  }
else
  ActionMailer::Base.smtp_settings = {
    :address => Brooklyn::Application.config.sendgrid.address,
    :port => Brooklyn::Application.config.sendgrid.port,
    :domain => Brooklyn::Application.config.sendgrid.domain,
    :authentication => :plain,
    :user_name => Brooklyn::Application.config.sendgrid.username,
    :password => Brooklyn::Application.config.sendgrid.password,
    :enable_starttls_auto => false
  }
end

Rails.logger.info("Sending mail via SMTP to #{ActionMailer::Base.smtp_settings[:address]}")
