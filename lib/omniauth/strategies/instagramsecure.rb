require 'omniauth-instagram'
require 'multi_json'

module OmniAuth
  module Strategies

    class InstagramSecure < Instagram
      option :name, 'instagram_secure'
    end
  end
end
