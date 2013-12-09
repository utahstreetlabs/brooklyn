Recaptcha.configure do |config|
  config.public_key  =  Brooklyn::Application.config.recaptcha.key
  config.private_key =  Brooklyn::Application.config.recaptcha.secret
end
