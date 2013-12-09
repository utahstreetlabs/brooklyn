Brooklyn::Mixpanel.token = Brooklyn::Application.config.tracking.mixpanel.token

Rails.logger.info("Reporting tracking events to Mixpanel") if Brooklyn::Mixpanel.token.present?


