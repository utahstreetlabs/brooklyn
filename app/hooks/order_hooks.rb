require 'typhoeus'

class OrderHooks
  TYPES = [:created, :updated, :deleted]

  class << self

    def post_headers(format, token, type)
      format = "application/#{format}; charset=utf-8"
      { :'Content-Type' => format, :'Accept' => format, :'X-Notification-Type' => type,
        :'Authorization' => "Basic #{ActiveSupport::Base64.encode64s("#{token}:")}"
      }
    end

    def fire(order, type)
      raise "Invalid OrderHook type '#{type}'" unless TYPES.include?(type)
      raise "Order hooks not configured for order #{order.id}" unless order.api_callback?

      api_config = order.listing.seller.api_config
      url = api_config.callback_url

      headers = post_headers(api_config.format, api_config.token, type.to_s.upcase)
      api_hash = { order: order.api_hash }
      data = api_config.format == 'json' ? api_hash.to_json : api_hash[:order].to_xml({root: 'order'})
      response = Typhoeus::Request.post(url, headers: headers, timeout: 20000, body: data)

      if (response.code / 100) != 2
        Rails.logger.error("Api Callback Error: #{response.body}. Response Code: #{response.code}")
        Airbrake.notify(error_class: "Error posting callback to api user", error_message: response.body,
          parameters: {headers: headers, body: data})
      end
    end
  end
end
