require 'context_base'

unless defined? Rails
  RSpec.configure do |config|
    config.before do
      ContextBase.logger = Rails.logger
      ContextBase.url_helpers = stub('url_helpers', root_url: 'http://example.com')
    end
  end
end
