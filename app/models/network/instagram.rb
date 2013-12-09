require 'network/base'

module Network
  class Instagram < Base
    def self.app_id
      # all OAuth networks have an id
      self.config.app_id
    end

    def self.app_secret
      # all OAuth networks have a secret
      self.config.app_secret
    end

    def self.omniauth_options
      {scope: self.scope}
    end

    def self.symbol
      :instagram
    end

    def self.as_secure
      :instagram_secure
    end

    def self.scope
      'basic relationships'
    end
  end
end
