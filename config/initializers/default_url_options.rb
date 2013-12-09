# ensure that we have default url options in the web app and in resque
Rails.application.routes.default_url_options = ActionMailer::Base.default_url_options
