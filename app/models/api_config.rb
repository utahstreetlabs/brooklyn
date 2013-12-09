require 'securerandom'

class ApiConfig < ActiveRecord::Base
  belongs_to :user

  def generate_token_if_necessary
    unless self.token
      begin
        self.token = SecureRandom.urlsafe_base64(24)
      end while self.class.exists?(token: token)
    end
  end
  before_validation :generate_token_if_necessary

  def self.authenticate_token(token)
    return nil unless token.present?
    api_config = find_by_token(token, include: :user)
    api_config && api_config.user.registered? ? api_config.user : nil
  end
end
