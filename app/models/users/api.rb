require 'active_support/concern'

module Users
  module Api
    extend ActiveSupport::Concern

    def find_or_create_api_config
      self.api_config or
        benchmark 'Created API config', level: :info do
          self.create_api_config!
      end
    end
  end
end
