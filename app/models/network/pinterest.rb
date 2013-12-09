require 'network/base'

module Network
  class Pinterest < Base
    def self.symbol
      :pinterest
    end

    def self.message_string_keys
      [:text]
    end

    def self.external_share_dialog_url(params = {}, options = {})
      "http://pinterest.com/pin/create/button/?url=%s&media=%s&description=%s" %
        [params[:link], params[:large_picture], params[:text]]
    end
  end
end
