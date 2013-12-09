class Api::GeckoboardController < ApiController
  def authenticate_token(token)
    token == Brooklyn::Application.config.api.token
  end
end
