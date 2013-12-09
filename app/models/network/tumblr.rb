require 'network/base'

module Network
  class Tumblr < Base
    def self.symbol
      :tumblr
    end

    def self.message_string_keys
      [:text]
    end

    def self.external_share_dialog_url(params={}, options={})
      "http://www.tumblr.com/share/photo?source=%s&caption=%s&clickthru=%s" % [params[:large_picture], params[:text], params[:link]]
    end
  end
end
