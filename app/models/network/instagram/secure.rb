require 'network/instagram'

module Network

  class Instagram::Secure < Instagram
    def self.app_id
      self.config.app_id_secure
    end

    def self.app_secret
      self.config.app_secret_secure
    end

    def self.as_secure
      nil
    end

    def self.as_insecure
      :instagram
    end

    def self.secure?
      true
    end

    def self.omniauth_provider
      :instagram_secure
    end
  end
end
