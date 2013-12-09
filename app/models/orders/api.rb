require 'active_support/concern'
require 'brooklyn/sprayer'
require 'hooks/publish_order_change'

module Orders
  module Api
    extend ActiveSupport::Concern

    def api_callback?
      listing.api?
    end

    def send_hook_to_api_seller(type)
      Hooks::PublishOrderChange.enqueue(self.id, type) if api_callback?
    end

    def api_hash
      {reference: reference_number, status: status, listing: listing.api_hash,
        buyer: buyer_shipping_hash, discount: discount, proceeds: listing.proceeds, payment_type: payment_type,
        order_time: created_at.to_time.to_i, link: self.class.url_helpers.api_order_url(self) }
    end

    def buyer_shipping_hash
      buyer_hash = [:name, :email, :uuid].each_with_object({}) { |k,h| h[k] = buyer.send(k) }
      if shipping_address
        [:line1, :line2, :city, :state, :zip, :phone].each do |key, hash|
          buyer_hash[key] = shipping_address.send(key)
        end
      end
      buyer_hash
    end
  end
end
